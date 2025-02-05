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
import itertools
import sys
import typing as t
import pathlib as p
import json as j

@dataclass
class MashRow:
    __slots__ = ("identity", "shared_hashes", "median_multiplicity", "p_value", "query_id", "query_note")
    identity: float
    shared_hashes: t.List[int]
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
    meta_genome_prog = "classify"
    best_match = "top"
    report_taxon_delimiter = ";"
    taxon_level_split = "__"
    taxonomic_classification_level = "g"  # the level at which to check for if sample is metagenomic
    alternate_taxa_allowed = 1  # The number of unique elements allowed in a set before the sample is classified as metagenomic, works with the taxonomic_classification_level constant

    def __init__(self, prog, mash_input, equivalent_taxa: t.Optional[p.Path]) -> None:
        self.equivalent_taxa = self.parse_equivalent_taxa(p.Path(equivalent_taxa))
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

    def parse_equivalent_taxa(self, taxa: p.Path):
        """
        Parse the equivalent taxa from the input JSON

        returns dict[str, str]: Where the key is from the split taxon string mapping to
        the shared key used for assigning equivalent taxa.
        """
        with taxa.open() as data_in:
            data = j.load(data_in)

        taxa_equivalent = defaultdict(lambda: set())
        for key, value in data.items():
            equivalent_values = itertools.chain.from_iterable(
                (map(lambda x: x.split(self.report_taxon_delimiter), value)))

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
        """
        levels = taxa_levels[self.taxonomic_classification_level]
        for k, v in self.equivalent_taxa.items():
            for taxa in v:
                if taxa in levels:
                    levels.remove(taxa)
                    levels.add(k)
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
    classify_arg_count = 4
    if len(sys.argv) == classify_arg_count:
        MashScreen(sys.argv[1], sys.argv[2], sys.argv[3])
    else:
        MashScreen(sys.argv[1], sys.argv[2], None)
