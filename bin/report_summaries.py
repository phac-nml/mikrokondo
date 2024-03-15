#! /usr/bin/env python
"""Convert the summary report json into a CSV, create a flattened json summary for individual data points as well
TODO code base for this script needs to be cleaned up quite a bit
TODO add static html table output

Matthew Wells: 2023-09-22
"""
from dataclasses import dataclass
from typing import Dict, Union
from collections import defaultdict
import os
import argparse
import json
import copy
import sys

@dataclass
class CleaningInfo:
    """Info about how to parse certain common fields from Mikrokondo
    field str: The fields name
    keep str|None: if multiple fields are associated with the value specify one to keep, or None to keep all
    trim_field int: when split on a delimiter which section of the list to keep
    """
    field: str
    keep: Union[str, None] = None
    trim_field: Union[int, None] = None

class JsonImport:
    """Intake json report to convert to CSV"""

    __key_order = {v.field: v for v in [CleaningInfo(field="QCStatus"),
                CleaningInfo(field="QCSummary"),
                CleaningInfo(field="QualityAnalysis", keep="message", trim_field=1),
                CleaningInfo(field="meta")]}
    __keep_keys = frozenset(__key_order.keys())
    __delimiter = "\t"
    __key_delimiter = "."

    def __init__(self, report_fp, output_name, sample_suffix):
        self.tool_data = None # TODO set this in output of group tool fields
        self.output_name = output_name
        self.output_transposed = os.path.splitext(os.path.basename(self.output_name))[0] + "_transposed.tsv"
        self.output_dir = os.path.dirname(self.output_name)
        self.flat_json = os.path.splitext(os.path.basename(self.output_name))[0] + "_flattened.json"
        self.qc_paths = []
        self.report_fp = report_fp
        self.flat_sample_string = sample_suffix
        self.data = self.ingest_report(self.report_fp)
        self.flat_data, self.common_fields, self.tool_fields, self.table = self.flatten_json(self.data)
        self.output_indv_json(self.flat_data)
        self.output_flat_json(self.flat_data)
        self.write_table(self.table)


    def write_table(self, table_data: Dict[str, Dict[str, str]]):
        """Arrange the table labels and write the table transposed and not

        #TODO write out each of the filtered fields than the tool data

        Args:
            table_data (Dict[str, Dict[str, str]]): Ordered sample information in an map
        """
        keys = set([k for k in table_data])
        ordered_keys = []

        # Get the wanted information to the top of the page
        poisoned_keys = set()
        for option in self.__key_order:
            option_criteria = self.__key_order[option]
            keep = filter(lambda x: x.startswith(option_criteria.field), keys)
            keep, poisoned = self.update_table_labels(table_data, list(keep), option_criteria)
            poisoned_keys.update(poisoned)
            ordered_keys.extend(keep)

        poisoned_keys = frozenset(poisoned_keys)
        scalar_keys = sorted(filter(lambda x: self.__key_delimiter not in x and x not in ordered_keys and x not in poisoned_keys, keys))
        ordered_keys.extend(scalar_keys)
        ordered_keys.extend(sorted([i for i in keys if i not in ordered_keys and i not in poisoned_keys]))
        row_labels = sorted([i for i in next(iter(table_data.values()))])

        self.write_tsv(table_data, row_labels, ordered_keys)
        self.write_transposed_tsv(table_data, row_labels, ordered_keys)

    def write_transposed_tsv(self, table_data, row_labels, ordered_keys):
        with open(self.output_transposed, "w") as output_table:
            output_table.write(f"{self.__delimiter}{self.__delimiter.join(ordered_keys)}")
            output_table.write("\n")
            for i in row_labels:
                output_table.write(f"{i}")
                for row in ordered_keys:
                    fixed_output = str(table_data[row][i]).replace("\n", " ")
                    output_table.write(f"{self.__delimiter}{fixed_output}")
                output_table.write("\n")

    def write_tsv(self, table_data, row_labels, ordered_keys):
        with open(self.output_name, "w") as output_table:
            output_table.write(f"{self.__delimiter}{self.__delimiter.join(row_labels)}")
            output_table.write("\n")
            for i in ordered_keys:
                output_table.write(f"{i}")
                for row in row_labels:
                    fixed_output = str(table_data[i][row]).replace("\n", " ")
                    output_table.write(f"{self.__delimiter}{fixed_output}")
                output_table.write("\n")

    def update_table_labels(self, table, keys, info: CleaningInfo):
        """Update table values to use new trimmed keys

        Args:
            table (_type_): _description_
            keys (_type_): _description_
        """
        split_keys = [i.split(self.__key_delimiter) for i in keys]
        processed_keys = []
        poisoned_keys = set()
        for previous, split_k in zip(keys, split_keys):
            if info.keep and info.keep in split_k:
                new_key = split_k[info.trim_field]
                processed_keys.append(new_key)
                table[new_key] = table[previous]
                poisoned_keys.add(previous)
                del table[previous]
            elif not info.keep:
                new_key = previous
                if info.trim_field is not None:
                    new_key = split_k[info.trim_field]
                    table[new_key] = table[previous]
                    del table[previous]
                processed_keys.append(new_key)
            else:
                poisoned_keys.add(previous)
                del table[previous]
        return sorted(processed_keys), poisoned_keys


    def make_table(self, data):
        """Create an aggregated table of report data from mikrokondo
        Args:
            data (_type_): _description_
            fields_order (_type_): _description_
            tool_data (_type_): _description_
        """

        sample_data = defaultdict(list)
        for k, v in data.items():
            keys = [i.split(self.__key_delimiter) for i in v.keys()]
            copy_keys = []
            tool_keys = set()
            for i in keys:
                if i[0] in self.__keep_keys or k == i[0]:
                    rep_key = i
                    if k == i[0]:
                        rep_key = i[1:]
                    copy_keys.append((self.__key_delimiter.join(rep_key), v[self.__key_delimiter.join(i)]))
                else:
                    sample_data[i[0]].append((self.__key_delimiter.join(i[1:]), v[self.__key_delimiter.join(i)]))
                    tool_keys.add(i[0])
            sample_data[k] = copy_keys
            for key in tool_keys:
                sample_data[key].extend(copy_keys)

        row_values = {k: "" for k in sample_data}
        output_table = dict()
        for key, value in sample_data.items():
            for v in value:
                if output_table.get(v[0]) is None:
                    output_table[v[0]] = copy.deepcopy(row_values)
                output_table[v[0]][key] = v[1]
        return output_table



    def flatten_json(self, data):
        """
        Recursively flatten json fields
        """
        sample_data = dict()
        for k, v in data.items():
            out = {}
            def flatten(x, name=f""):
                if isinstance(x, dict):
                    for k in x:
                        flatten(x[k], name + k + self.__key_delimiter)
                elif isinstance(x, list):
                    i = 0
                    for k in x:
                        flatten(k, name + str(i) + self.__key_delimiter)
                        i += 1
                else:
                    out[name[:-1]] = x
            flatten(v)
            sample_data[k] = out

        output_table = self.make_table(sample_data)
        sample_data, top_level_keys, tool_keys = self.remove_prefix_id_fields(sample_data)
        return sample_data, top_level_keys, tool_keys, output_table


    def remove_prefix_id_fields(self, flattened_dict):
        """
        Metagenomic samples in mikrokondo have individual data points nested under a
        common prefix of the id values sample name. that can be removed to create a
        friendly json structure per a species found in each sample.

        flattened_dict: Flattened json data as a non nested dictionary with key value pairs

        returns:
        reformatted_data: prefix stripped key names (new key names)
        top_level_keys: keys that must be included in all output
        tool_level_keys: keys for items that correspond to tool output
        """
        reformatted_data = dict()
        tool_keys = set()
        tool_data = defaultdict(list)
        top_level_keys = set()


        for key, value in flattened_dict.items():
            reformatted_data[key] = dict()
            temp = reformatted_data[key]
            for k, v in value.items():
                item_key = k

                name_striped = k.removeprefix(f"{key}.")
                item_key = name_striped.removeprefix(f"{key}_")
                if item_key != k:
                    tool = k.split(".")
                    tool_keys.add(tool[1]) # only first level is key 1, and is added in the script
                    tool_data[tool[1]].append((tool[2:], v, key))
                else:
                    top_level_keys.add(item_key)
                temp[item_key] = v

        #self.tool_data = tool_data
        return reformatted_data, top_level_keys, tool_keys


    def ingest_report(self, report_fp):
        """
        report_fp: File path to the json report to be read in
        """
        data = None
        with open(report_fp, "r", encoding="utf8") as report:
            data = json.load(report)
        return data

    def output_flat_json(self, flattened_data):
        """Flattened json data to output to a final location

        Args:
            flattened_data (json: Dict[sample_id: Dict[tool_info: value]]):
        """
        with open(os.path.join(self.output_dir, self.flat_json), "w") as output:
            d_out = json.dumps(flattened_data, indent=2)
            output.write(d_out)

    def output_indv_json(self, flattened_data):
        """Flattened json data to output to a final location

        Args:
            flattened_data (json: Dict[sample_id: Dict[tool_info: value]]):
        """
        for k, v in flattened_data.items():
            with open(os.path.join(self.output_dir, k + self.flat_sample_string), "w") as output:
                json_data = json.dumps({k: v}, indent=2)
                output.write(json_data)


    def to_file(self):
        with open(self.output_name, "w") as out_file:
            out_file.write(self.__delimiter)  # first column is index
            for i in self.formatted_data:
                out_file.write(f"{i[0]}{self.__delimiter}")
            out_file.write("\n")
            for i in self.rows:
                out_file.write(f"{i}{self.__delimiter}")
                for ii in self.formatted_data:
                    val_write = str(ii[1][i])
                    if "\n" in val_write or " " in val_write:
                        out_file.write(f'"{val_write}"')
                    else:
                        out_file.write(val_write)
                        # out_file.write(str(ii[1][i]).replace('\n', ' \\'))
                    out_file.write(self.__delimiter)
                out_file.write("\n")






def main_(args_in):
    default_samp_suffix = "_flat_sample.json"
    parser = argparse.ArgumentParser("Table Summary")
    parser.add_argument("-f", "--file-in", help="Path to the mikrokondo json summary")
    parser.add_argument("-s", "--sample-tag", help="Optional suffix and extension to name output samples.", default=default_samp_suffix)
    parser.add_argument("-o", "--out-file", help="output name plus the .tsv extension e.g. prefix.tsv")
    args = parser.parse_args(args_in)
    if os.path.isfile(args.file_in):
        JsonImport(args.file_in, args.out_file, args.sample_tag)
    else:
        sys.stderr.write(f"{args.file_in} does not exist.\n")
        sys.exit(-1)


if __name__ == "__main__":
    # pass json file to program to parse it
    main_(sys.argv[1:])
