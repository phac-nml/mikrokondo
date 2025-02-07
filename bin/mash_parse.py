#! /usr/bin/env python
"""Determine if a sample is a metagenomic sequencing run or a single isolate


    As I did not want to re-implement the mash screen class or deal with python imports
    in nextflow, two programs are currently embeded in the class the *classify* option for
    determinging if a sample is metagenomic or not and the *top* options to get the top hit
    from a mash screen file
"""
#! have ties return a null result
from dataclasses import dataclass
from collections import defaultdict
import argparse
import itertools
import sys
import typing
import pathlib
import json


__META_GENOME_PROG__ = "classify"
__BEST_MATCH__ = "top"

@dataclass
class MashRow:
    __slots__ = ("identity", "shared_hashes", "median_multiplicity", "p_value", "query_id", "query_note")
    identity: float
    shared_hashes: typing.List[int]
    median_multiplicity: int
    p_value: float
    query_id: str
    query_note: str  # default as not all databases created have comments included

    def __init__(self, *args):
        self.identity = float(args[0])
        self.shared_hashes = [int(i) for i in args[1].split("/")]
        self.median_multiplicity = int(args[2])
        self.p_value = float(args[3])
        self.query_id = args[4]
        self.query_note = str(args[5]) if [args[5]] else str(None)


class MashScreen:
    """From a mash screen output parse it and determine
    if a sample is metagenomic or a single isolate
    """


    _screen_delimiter = "\t"

    # arbitrarily defined cutoffs
    coefficient_of_variation_cutoff = 0.40
    skewness_cutoff = 4
    percent_identity_cutoff = 0.90
    meta_genome_prog = __META_GENOME_PROG__
    best_match = __BEST_MATCH__
    report_taxon_delimiter = ";"
    taxon_level_split = "__"
    taxonomic_classification_level = "g"  # the level at which to check for if sample is metagenomic
    alternate_taxa_allowed = 1  # The number of unique elements allowed in a set before the sample is classified as metagenomic, works with the taxonomic_classification_level constant

    def __init__(self, prog, mash_input, equivalent_taxa: typing.Optional[pathlib.Path]):
        if equivalent_taxa is not None:
            self.equivalent_taxa = self.parse_equivalent_taxa(pathlib.Path(equivalent_taxa))
        self.mash_input = mash_input
        self._mash_data = self.parse_mash_screen()
        if self.meta_genome_prog == prog:
            if self.metagenomic_p(self._mash_data):
                sys.stdout.write("true")
            else:
                sys.stdout.write("false")
        elif self.best_match == prog:
            most_likely_match = self.top_hit(self._mash_data)
            sys.stdout.write(f"{most_likely_match}")
        else:
            sys.stderr.write(f"Option {prog} not recognized.\n")
            sys.stderr.write(f"Options are: {self.meta_genome_prog, self.best_match}\n")
            sys.exit(-1)

    def get_taxa_level(self, taxa: str):
        """
        Return taxa level for a field in the query note.
        """
        return taxa[:taxa.index(self.taxon_level_split)]

    def parse_equivalent_taxa(self, taxa: pathlib.Path):
        """
        Parse the equivalent taxa from the input JSON

        returns dict[str, str]: Where the key is from the split taxon string mapping to
        the shared key used for assigning equivalent taxa.
        """
        with taxa.open() as data_in:
            data = json.load(data_in)

        taxa_equivalent = defaultdict(lambda: set())
        for key, value in data.items():
            """
            The below operation takes in the array of equivalent taxonomy values from  `equivalent_taxa.json`
            an example of the array can be seen below:
            [
                f__Enterobacteriaceae;g__Escherichia;s__Escherichia coli",
                f__Enterobacteriaceae;g__Shigella;s__Shigella dysenteriae"
            ]

            The map process, splits each value in the array on the taxon delimiter value e.g. ';'
                e.g.
                    [
                        [f__Enterobacteriaceae, g__Escherichia, s__Escherichia coli],
                        [f__Enterobacteriaceae, g__Shigella, s__Shigella dysenteriae]
                    ]

            The values split on the delimited will then be in separate lists, that need to be flattened
            which itertools.chain.from_iterable does for us.

            The listed values are then iterated over and only the taxonomic level
            of interest (specified taxonomic_classification_level) is stored in the dictionary of equivalent values.

            Only the taxonomic level of interest is stored to prevent the stored sets from increasing in size.

            The final result is a dictionary with the hits of:
            taxa_equivalent: {
                Escherichia: { g__Escherichia, g__Shigella},
                Example: { g__genera1, g__genera2},
            }

            """
            equivalent_values = itertools.chain.from_iterable(
                map(lambda x: x.split(self.report_taxon_delimiter), value))

            for v in equivalent_values:
                if self.get_taxa_level(v) == self.taxonomic_classification_level:
                    taxa_equivalent[key].add(v)
        return taxa_equivalent

    def parse_flatten_queries(self, mash_data):
        """Flatten the mash query string responses"""
        taxa_map = defaultdict(lambda: set())
        for i in mash_data:
            for taxa in i.query_note.split(self.report_taxon_delimiter):
                taxa_map[self.get_taxa_level(taxa)].add(taxa)
        return taxa_map

    def normalize_taxa(self, taxa_levels: dict[str, set[str]]):
        """
        Reduce equivalent taxa into homogenous groups.

        The taxa levels is a dictionary containing the set of the contained taxa
        at a given taxonomic level.
        An example of the input data is as follows:
        taxa_levels = {
            k: {bacteria},
            p: {Pseudomonadota},
            c: {Gammaproteobacteria},
            o: {Enterobacterales},
            f: {Enterobacteriaceae},
            g: {g__Escherichia, g__Shigella}
        }

        As only one taxonomic level is used for differentiation of contamination
        we extract only the required level to process (e.g. self.taxonomic_classification_level = 'g')

        {g: {g__Escherichia, g__Shigella}} = taxa_levels[self.taxonomic_classification_level]

        Within the equivalent_taxa object each taxa at a specific level is mapped back to a key.
        e.g. {Escherichia: {g__Escherichia, g__Shigella}}

        we then loop through each key and value of the equivalent taxa, and check if each value of the
        equivalent taxa exists in the our input levels e.g. {g: {g__Escherichia, g__Shigella}}

        Every time a value of our equivalent taxa is found in our input values we remove it and add in
        the or "equivalent value" which is the key of our equivalent taxa.

        """

        levels = taxa_levels[self.taxonomic_classification_level]
        for k, v in self.equivalent_taxa.items():
            if levels & v: # check if sets contain shared items
                levels -= v # remove the shared items
                levels.add(k) # add in the shared key for the equivalent taxa
        return taxa_levels

    def metagenomic_p(self, mash_data):
        """Generate summary metrics of the mash screen data

        Args:
            mash_data (List[MashRow]): list of MashRow data
        """
        data = filter(lambda x: x.identity > self.percent_identity_cutoff, mash_data)
        taxa_levels = self.parse_flatten_queries(data)
        taxa_levels = self.normalize_taxa(taxa_levels)
        if len(taxa_levels[self.taxonomic_classification_level]) > self.alternate_taxa_allowed:
            return True
        return False

    def top_hit(self, mash_data):
        """Sort and identify the top mash hit from a screen file"""
        # ! TODO validate this logic works, and that there are no redundant sorts
        mash_data = [i for i in mash_data if i.identity >= self.percent_identity_cutoff]
        if not mash_data:
            return "No Species Identified"

        mash_data.sort(reverse=True, key=lambda x: x.identity)
        mash_data.sort(reverse=False, key=lambda x: x.p_value)
        mash_data.sort(reverse=True, key=lambda x: x.shared_hashes[0])
        try:
            best_option = mash_data[0]
        except IndexError:
            sys.stderr.write(f"No top hit in mash file. Something went wrong perhaps input file was empty.\n")
            sys.exit(-1)
        return best_option.query_note.split(self.report_taxon_delimiter)[-1].replace('"', "")

    def parse_mash_screen(self):
        """Parse a mash screen input and convert it too input types"""
        mash_rows = []
        with open(self.mash_input, "r") as mash_in:
            for line in mash_in.readlines():
                row = line.strip().replace('"', '').split("\t")
                parsed = MashRow(*row)
                mash_rows.append(parsed)
        return mash_rows

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Script for parsing mash outputs in mikrokondo",
    )

    parser.add_argument("-r", "--run-mode",
                        help="Run mode for the mash parse script.",
                        choices=[__META_GENOME_PROG__, __BEST_MATCH__],
                        required=True)

    parser.add_argument("-i", "--input",
                        help="Mash screen input samples.",
                        required=True)

    parser.add_argument("-e", "--equivalent-taxa",
                        help="Configuration file containing equivalent taxa.",
                        required=False,
                        default=None)

    args = parser.parse_args()
    if args.run_mode == __META_GENOME_PROG__ :
        MashScreen(args.run_mode, args.input, args.equivalent_taxa)
    else:
        MashScreen(args.run_mode, args.input, None)
