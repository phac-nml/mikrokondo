#! /usr/bin/env python

from typing import List
import pandas as pd
import argparse
import sys
from os import path
from functools import partial

def join_entries(entries: List, delimiter: str):
    str_entries = [str(e) for e in entries]
    return delimiter.join(str_entries)

script_name = path.basename(path.realpath(sys.argv[0]))

def main(argv=None):
    parser = argparse.ArgumentParser(prog=script_name, description='Group output tabular files by specified keys')
    parser.add_argument(
        '-k|--key',
        action='store',
        dest="key",
        type=str,
        help="Key to group columns of tabular files on.",
        default=None,
        required=True
    )
    parser.add_argument(
        '-d|--file-delimiter',
        action='store',
        dest='file_delimiter',
        type=str,
        help="The delimiter of the input and output files [\\t].",
        default='\t',
        required=False)
    parser.add_argument(
        '-g|--grouby-delimiter',
        action='store',
        dest='groupby_delimiter',
        type=str,
        help="The delimiter used to join values when grouping [,].",
        default=',',
        required=False)
    parser.add_argument(
        '-i|--input',
        action='store',
        dest='input',
        type=str,
        help="The name of the input file of tabular data.",
        default=None,
        required=True)
    parser.add_argument(
        '-o|--output',
        action='store',
        dest='output',
        type=str,
        help="The name of the output file for tabular data.",
        default=None,
        required=True)

    args = parser.parse_args(argv)

    input_df = pd.read_csv(args.input, sep=args.file_delimiter)

    join_entries_delim = partial(join_entries, delimiter=args.groupby_delimiter)

    output_df = input_df.groupby(args.key).agg(join_entries_delim)
    output_df.to_csv(args.output, sep=args.file_delimiter)

    return 0

if __name__ == "__main__":
    sys.exit(main())