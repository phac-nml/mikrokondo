#! /usr/bin/env python
"""Convert the summary report json into a CSV
TODO code base for this script needs to be cleaned up quite a bit
TODO add static html table output

Matthew Wells: 2023-09-22
"""
from collections import defaultdict
import os
import argparse
import json
import copy
import re
import sys

class JsonImport:
    """Intake json report to convert to CSV
    """
    __depth_limit = 10
    __keep_keys = set(["meta", "QualityAnalysis", "QCSummary", "QCStatus"])
    __delimiter = "\t"

    def __init__(self, report_fp, output_name):
        self.output_name = output_name
        self.qc_paths = []
        self.report_fp = report_fp
        self.data = self.ingest_report(self.report_fp)
        self.normalized, self.rows = self.flatten_groups(self.data)
        self.formatted_data = self.format_for_csv(self.normalized, self.rows)
        self.to_file()


    def to_file(self):
        with open(self.output_name, "w") as out_file:
            out_file.write(self.__delimiter) # first column is index
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
                        #out_file.write(str(ii[1][i]).replace('\n', ' \\'))
                    out_file.write(self.__delimiter)
                out_file.write("\n")

    def format_for_csv(self, results, rows):
        row = {k: "" for k in rows}
        data = []
        for k, v in results.items():
            n_row = copy.deepcopy(row)
            sample_data = [key for key in v.keys() if key != "summary" ]
            for item in v["summary"]:
                n_row[item[0]] = item[1]
            n_row_samp = copy.deepcopy(n_row)
            for key in sample_data:
                n_row_samp = copy.deepcopy(n_row)
                for k1 in v[key]:
                    n_row_samp[k1[0]] = k1[1]
                data.append((key, n_row_samp))
        return data

    @staticmethod
    def check_field(dict_, value):
        if dict_.get(value) is None:
            return False
        return True

    def flatten_groups(self, data):
        """Use known output structure to format groups, if metagenomic some fields will be missing
        Args:
            data (_type_): _description_
        """
        sample_data_overview = dict()
        rows = set()
        meta_data_rows = set()
        qc_analysis_rows = set()
        qc_status_rows = set()
        for k, v in data.items():
            results = []

            if self.check_field(v, "QCStatus"):
                qc_status_p = True
                qc_status = v["QCStatus"]
                qc_status_rows.add("QCStatus")
                results.append(("QCStatus", qc_status))

            if self.check_field(v, "meta"):
                meta_data = v["meta"]
                for field, outcome in meta_data.items():
                    meta_data_rows.add(field)
                    results.append((field, outcome))

            if self.check_field(v, "QualityAnalysis"):
                qc_data = v["QualityAnalysis"]
                for i in qc_data:
                    qc_analysis_rows.add(i)
                results.extend(self.get_quality_analysis_fields(qc_data))

            if self.check_field(v, "QCSummary"):
                qc_summary = v["QCSummary"]
                sample_data = [d_key for d_key in v.keys() if d_key not in self.__keep_keys]
                results.append(("QCSummary", qc_summary.replace("\n", ". ")))

            sample_data_overview[k] = dict()
            sample_data_overview[k]["summary"] = copy.deepcopy(results)
            for key in sample_data:
                sample_level_data = []
                for k1, v1 in v[key].items():
                    self.recurse_json(v1, k1, sample_level_data)
                [rows.add(key[0]) for key in sample_level_data]
                sample_data_overview[k][key] = sample_level_data

        qc_status_rows = list(qc_status_rows)
        qc_status_rows.extend(list(qc_analysis_rows))
        qc_status_rows.append("QCSummary")
        qc_status_rows.extend(list(meta_data_rows))
        #meta_data_rows = list(meta_data_rows)
        #meta_data_rows.extend(list(qc_analysis_rows))
        #meta_data_rows.append("QCSummary")
        rows = list(rows)
        rows.sort(reverse=True)
        qc_status_rows.extend(rows)
        #meta_data_rows.extend(rows)

        #return (sample_data_overview, meta_data_rows)
        return (sample_data_overview, qc_status_rows)

    def get_quality_analysis_fields(self, qc_fields):
        fields = []
        for k, v in qc_fields.items():
            if v.get("field") is None:
                fields.append((k, v["message"]))
            else:
                fields.append((v["field"], v["message"]))
        return fields


    def recurse_json(self, dict_, prev_key, results):
        if isinstance(dict_, dict):
            for key in dict_:
                if isinstance(dict_[key], dict):
                    self.recurse_json(dict_[key], prev_key=prev_key+"."+key, results=results)
                elif isinstance(dict_[key], list):
                    for val in dict_[key]:
                        if isinstance(val, dict):
                            self.recurse_json(val, prev_key=prev_key+"."+key+"."+val, results=results)
                        else:
                            results.append((prev_key + "." + key, dict_[key]))
                else:
                    results.append((prev_key + "." + key, dict_[key]))
        else:
            if isinstance(dict_, str):
                results.append((prev_key, dict_.replace("\"", "")))
            elif isinstance(dict_, float):
                results.append((prev_key, dict_))
            elif isinstance(dict_, list):
                for val in dict_:
                    if isinstance(val, dict):
                        self.recurse_json(val, prev_key=prev_key, results=results)
                    else:
                        results.append((prev_key, dict_))
            else:
                # issues with iterables here
                sys.stderr.write(f"Having issues with report JSON value {prev_key}. Data value {dict_}\n")
                results.append((prev_key, dict_))


    def regroup_data(self, paths):
        """Re-group data into a form that is easier to put into CSV format

        Args:
            paths (_type_): _description_
        """
        sample_specific = dict()
        for p in paths:
            sample = p[0][0]
            sample_lv2 = p[0][1]
            if sample_specific.get(sample) is None:
                sample_specific[sample] = dict()
            if sample_specific[sample].get(sample_lv2) is None:
                sample_specific[sample][sample_lv2] = dict()
            sample_specific[sample][sample_lv2][p[0][-2]][p[0][-1]] = p[1]
        # Grouped data can make nice JSON for Irida Next
        return sample_specific

    def subset_paths(self):
        """Could be made faster by using the dictionary as input
        """
        paths = []
        for k in self.qc_paths:
            sample = k[0][0]
            vals = k[0][1:]
            for val in self.fields:
                if val in vals:
                    paths.append(k)
        return paths


    def get_samples(self, dict_obj):
        keys = dict_obj.keys()
        return keys

    def recurse_dict(self, dict_, depth, info, path):
        """TODO change to not store values

        Args:
            dict_ (_type_): _description_
            depth (_type_): _description_
            info (_type_): _description_
            path (_type_): _description_
        """
        depth += 1
        if depth < 10:
            for k, v in dict_.items():
                if type(v) is dict:
                    new_path = copy.deepcopy(path)
                    new_path.append(k)
                    self.recurse_dict(v, depth, info, new_path)
                elif type(v) is list:
                    for val in v:
                        new_path = copy.deepcopy(path)
                        new_path.append(k)
                        self.recurse_dict(val, depth, info, new_path)
                else:
                    new_path = copy.deepcopy(path)
                    new_path.append(k)
                    self.qc_paths.append((new_path, v))

    def get_all_fields(self, dict_obj, samples):
        """Get all the fields

        Args:
            dict_obj (_type_): _description_
        """

        for i in samples:
            info = []
            path = [i]
            self.recurse_dict(dict_obj[i], 0, info, path)


    def normalize_overlapping_fields(self, normalized_dict):
        """Normalize overlapping json fields, e.g. if a sample is metagenomic and has species data
        copied, add in the fastp data to each part

        TODO this needs tests

        Args:
            normalized_dict (_type_): _description_
        """
        keys_drop = []
        for key in normalized_dict:
            expr = re.compile(f"{key}_.+_binned")
            base_val = normalized_dict[key][key]
            meta_info = normalized_dict[key]["meta"]
            for s_key in normalized_dict[key].keys():
                # keys for metagenomic fit pattern
                if expr.match(s_key) is not None:
                    keys_drop.append(key)
                    for k, v in base_val.items():
                        normalized_dict[key][s_key][k] = v
        self.create_csv(normalized_dict)

    def ingest_report(self, report_fp):
        data = None
        with open(report_fp, 'r', encoding='utf8') as report:
            data = json.load(report)
        return data


def main_(args_in):
    parser = argparse.ArgumentParser("Table Summary")
    parser.add_argument("-f", "--file-in", help="Path to the mikrokondo json summary")
    parser.add_argument("-o", "--out-file", help="output name plus the .tsv extension e.g. prefix.tsv")
    args = parser.parse_args(args_in)
    if os.path.isfile(args.file_in):
        JsonImport(args.file_in, args.out_file)
    else:
        sys.stderr.write(f"{args.file_in} does not exist.\n")
        sys.exit(-1)

if __name__ == "__main__":
    # pass json file to program to parse it
    main_(sys.argv[1:])
