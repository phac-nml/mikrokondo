"""
Reformat a mikrokondo json to un-nest dotter parameters

2024-03-14: Matthew Wells
"""

from __future__ import annotations

import json
import logging
import os
import sys
import argparse
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class Constants:
    delimiter: str = "."
    extraction_field: str = "properties"
    properties_type: str = "object"
    type_field: str = "type"
    nesting_field: str = "definitions"
    allof_field: str = "allOf"
    ref_key: str = "$ref"


def drop_all_of_fields(schema_all_of: list, fields: set):
    """
    Drop the fields in allOf of the schema that are erased

    schema_all_of list: The allOf list from the schema.json file id'd in the ref keys
    fields set: the field values to delete
    """
    defs_delete = frozenset([create_all_of_ref(i) for i in fields])

    return list(filter(lambda x: x[Constants.ref_key] not in defs_delete, schema_all_of))

def create_all_of_ref(field):
    return f"#/{Constants.nesting_field}/{field}"


def denested_information(keys: list[str], last_value: dict) -> dict:
    """
    Recursively append new dictionaries with sub information being propagated throughout the dictionary
    chain

    keys List[str]: list of keys to recursively implement as dictionaries are chained together
    last_value dict: Last data entry to be appended to the chained dictionaries
    """

    if len(keys) == 1:
        return last_value

    new_chain: dict = {}
    temp = new_chain
    for i in keys[0:-1]:
        temp[i] = {}
        temp[i][Constants.type_field] = Constants.properties_type
        temp[i][Constants.extraction_field] = {}
        temp = temp[i][Constants.extraction_field]

    temp[Constants.type_field] = Constants.properties_type
    temp[Constants.extraction_field] = {keys[-1]: last_value}

    return new_chain




def nest_schema(properties: dict) -> dict:
    """Convert a 'dotted' schema into a nested json
    e.g.
    properties: {
        "seqkit.singularity": {
            type: "string",
        }
    }

    into
    "properties" : {
        "singularity" : {
            "type": string
        }
    }

    properties (dict): an existing list of json properties
    """

    new_dict: dict = {}
    poisoned_keys = []
    for key, values in properties.items():
        if Constants.delimiter not in key:
            continue
        split_key = key.split(Constants.delimiter)

        if new_dict.get(split_key[0]) is None:
            new_dict[split_key[0]] = {}
            new_dict[split_key[0]][Constants.type_field] = Constants.properties_type
            new_dict[split_key[0]][Constants.extraction_field] = {}

        denested_data = denested_information(split_key[1:], values)
        if denested_data != values:
            # multiple fields to be set, update the properties instead of overwriting it

            temp = denested_data
            nd_temp = new_dict[split_key[0]][Constants.extraction_field]
            for i in split_key[1:-1]:
                if nd_temp.get(i) is None:
                    nd_temp[i] = {}
                    nd_temp[i][Constants.type_field] = temp[i][Constants.type_field]
                    nd_temp[i][Constants.extraction_field] = {}

                nd_temp = nd_temp[i][Constants.extraction_field]
                temp = temp[i][Constants.extraction_field]

            nd_temp[split_key[-1]] = temp[Constants.extraction_field][split_key[-1]]

        else:
            new_dict[split_key[0]][Constants.extraction_field][split_key[1]] = denested_data

        poisoned_keys.append(key)

    for i in poisoned_keys:
        del properties[i]
    properties.update(new_dict)
    return properties


def read_json(fp: str) -> json:
    """
    Read and return json file.

    input
    """
    if not os.path.isfile(fp):
        logger.critical("File not found: %s, Bailing.", fp)
        sys.exit(1)
    with open(fp, encoding="utf8") as in_file:
        return json.load(in_file)


def nest_properties(schema: dict) -> dict:
    """
    Extract all
    """
    type_field = schema.get(Constants.type_field)
    properties = None
    if type_field and type_field == Constants.properties_type:
        properties = schema.get(Constants.extraction_field)
        if properties is None:
            raise KeyError("No properties field in json schema.")

    for k, props in schema[Constants.nesting_field].items():
        new_properties = nest_schema(properties=props[Constants.extraction_field])
        del schema[Constants.nesting_field][k][Constants.extraction_field]
        schema[Constants.nesting_field][k][Constants.extraction_field] = new_properties


    new_properties = nest_schema(properties=properties)
    del schema[Constants.extraction_field]
    schema[Constants.extraction_field] = new_properties
    drop_keys = reorganize_schema(schema)
    schema[Constants.allof_field] = drop_all_of_fields(schema[Constants.allof_field], drop_keys)

    return schema

def drop_keys_repeated(schema):
    """
    Keys in the properties section need may be repeated in the definitions, those in the definitions
    need to be removed from the properties field
    """
    common_keys = schema[Constants.nesting_field].keys() & schema[Constants.extraction_field].keys()
    for key in common_keys:
        del schema[Constants.extraction_field][key]
    return schema

def reorganize_schema(schema) -> set:
    """Take a newly nested schema and merge paramter definitions together to prevent errors
    TODO break this function up into smaller sections

    definitions dict: Updated definitions field in a json schema
    return drop_keys set: Additional fields to delete from the schema after processing
    """


    definitions = schema[Constants.nesting_field]
    top_lvl_keys = frozenset(definitions.keys())
    properties_keys = frozenset(schema[Constants.extraction_field].keys())
    drop_keys = set()
    for k, v in definitions.items():
        tpl_keys = [i for i in v[Constants.extraction_field].keys() if i in top_lvl_keys]
        if not tpl_keys or len(tpl_keys) == 1:
            continue
        for i in tpl_keys:
            definitions[i][Constants.extraction_field][i].update(v[Constants.extraction_field][i][Constants.extraction_field])
            del v[Constants.extraction_field][i]
            if schema[Constants.extraction_field].get(i):
                del schema[Constants.extraction_field][i]
        drop_keys.add(k)

    for k in drop_keys:
        del definitions[k]

    for k, v in definitions.items():
        common_keys = v[Constants.extraction_field].keys() & properties_keys
        if not common_keys:
            continue
        for i in common_keys:
            props = schema[Constants.extraction_field].get(i)
            if props:
                v[Constants.extraction_field][i].update(props[Constants.extraction_field])
                del schema[Constants.extraction_field][i]

    return drop_keys

def dump_schema(schema: dict, output_fp: str):
    """Dump the updated schema

    schema dict: The updated json schema
    output_fp: the location for the new json schema
    """
    with open(output_fp, 'w', encoding='utf8') as output_file:
        json.dump(schema, output_file, indent=2)


def reformat_schema(input_json, output):
    """Resolve issues with nested paramters in a nextflow schema.json

    input os.Path: file path to input file
    output os.Path: file path to output file
    """
    schema_in = read_json(input_json)
    updated_schema = nest_properties(schema_in)
    dump_schema(updated_schema, output)

def main(argv=None):
    parser = argparse.ArgumentParser(prog=__file__, description="Fromat a nextflow")
    parser.add_argument("-i", "--input-file",
                        type=str,
                        help="input file",
                        default=None,
                        required=True
                        )
    parser.add_argument("-o", "--output",
                        required=True)
    args = parser.parse_args(argv)
    reformat_schema(args.input_file, args.output)

if __name__ == "__main__":
    sys.exit(main())
