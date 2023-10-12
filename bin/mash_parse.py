#! /usr/bin/env python
"""Determine if a sample is a metagenomic sequencing run or a single isolate


    As I did not want to re-implement the mash screen class or deal with python imports
    in nextflow, two programs are currently embeded in the class the *classify* option for
    determinging if a sample is metagenomic or not and the *top* options to get the top hit
    from a mash screen file
"""
# TODO having no input file is not being handled properly
# TODO have ties return a null result
from typing import NamedTuple, List
from dataclasses import dataclass
from collections import defaultdict
import statistics
import os
import math
import sys

#class MashRow(NamedTuple):
#    identity: float
#    shared_hashes: List[int]
#    median_multiplicity: int
#    p_value: float
#    query_id: str
#    query_note: str = None # default as not all databases created have comments included


@dataclass
class MashRow:
    __slots__ = ('identity', 'shared_hashes', 'median_multiplicity', 'p_value', 'query_id', 'query_note')
    identity: float
    shared_hashes: List[int]
    median_multiplicity: int
    p_value: float
    query_id: str
    query_note: str # default as not all databases created have comments included

    def __init__(self, *args):
        self.identity = float(args[0])
        self.shared_hashes = [int(i) for i in args[1].split('/')]
        self.median_multiplicity = int(args[2])
        self.p_value = float(args[3])
        self.query_id= args[4]
        self.query_note = str(args[5]) if [args[5]] else str(None)

class MashScreen:
    """From a mash screen output parse it and determine
    if a sample is metagenomic or a single isolate
    """

    # TODO this is coupled to the Mashrow class :( address later if it becomes an issues
    # TODO perhaps just use a class, with a __slots__ atribute set to handle the mash rows
    #       allowing for use of an init func
    #mash_field_ops = [
    #    lambda identity: float(identity),
    #    lambda shared_hashes: [int(i) for i in shared_hashes.split('/')],
    #    lambda multiplicity: int(multiplicity),
    #    lambda p_value: float(p_value),
    #    lambda query: str(query),
    #    lambda q_note: str(q_note) if q_note else str(None) # query note needs to be optional
    #]

    _screen_delimiter = "\t"

    # arbitrarily defined cutoffs
    coefficient_of_variation_cutoff = 0.40
    skewness_cutoff = 4
    percent_identity_cutoff = 0.90
    meta_genome_prog = "classify"
    best_match = "top"
    report_taxon_delimiter = ';'
    taxon_level_split = "__"
    taxonomic_classification_level = 'g' # the level at which to check for if sample is metagenomic
    alternate_taxa_allowed = 1 # The number of unique elements allowed in a set before the sample is classified as metagenomic, works with the taxonomic_classification_level constant

    def __init__(self, prog, mash_input) -> None:

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

    def coefficient_variation(self, mash_data):
        """Calculate the coefficient of variation from mash screen in efforts of determine
        if a sample is metagenomic.

        """
        perc_id_list = [i.identity for i in mash_data]
        mash_entries_len = len(mash_data)

        avg_perc_id = statistics.fmean(perc_id_list)
        median_perc_id = statistics.median(perc_id_list)
        stdev_id = statistics.stdev(perc_id_list)
        coeff_v = stdev_id / avg_perc_id
        # calculating skew
        #skewness = sum([math.pow(i - avg_perc_id, 3) for i in perc_id_list]) / ((mash_entries_len - 1) * math.pow(stdev_id, 3))
        # using pearsons second skewness calculation
        skewness = (3 * (median_perc_id - avg_perc_id)) / stdev_id
        if coeff_v >= self.coefficient_of_variation_cutoff or self.skewness_cutoff <= abs(skewness):
            return True
        return False

    def parse_flatten_queries(self, mash_data):
        """Flatten the mash query string responses so different phylogenetic thresholds
        """
        taxa_map = defaultdict(lambda: set())
        for i in mash_data:
            path = []
            for taxa in i.query_note.split(self.report_taxon_delimiter):
                taxa_map[taxa[:taxa.index(self.taxon_level_split)]].add(taxa)
        return taxa_map


    def metagenomic_p(self, mash_data):
        """Generate summary metrics of the mash screen data

        Args:
            mash_data (List[MashRow]): list of MashRow data
        """
        data = filter(lambda x: x.identity > self.percent_identity_cutoff, mash_data)
        taxa_levels = self.parse_flatten_queries(data)
        if len(taxa_levels[self.taxonomic_classification_level]) > self.alternate_taxa_allowed:
            return True
        return False
        #return self.coefficient_variation(mash_data)


    def top_hit(self, mash_data):
        """Sort and identify the top mash hit from a screen file
        """
        # ! TODO validate this logic works, and that there are no redundant sorts
        mash_data = [i for i in mash_data if i.identity >= self.percent_identity_cutoff]
        if not mash_data:
            return "No Species Identified"

        mash_data.sort(reverse=True, key=lambda x: x.identity)
        mash_data.sort(reverse=False, key= lambda x: x.p_value)
        mash_data.sort(reverse=True, key=lambda x: x.shared_hashes[0])
        try:
            best_option = mash_data[0]
        except IndexError:
            sys.stderr.write(f"No top hit in mash file. Something went wrong perhaps input file was empty.\n")
            sys.exit(-1)
        return best_option.query_note.split(self.report_taxon_delimiter)[-1]



    def parse_mash_screen(self):
        """Parse a mash screen input and convert it too input types
        """
        mash_rows = []
        with open(self.mash_input, 'r') as mash_in:
            for line in mash_in.readlines():
                row = line.strip().split("\t")
                #parsed = MashRow(*[f(i) for f, i in zip(self.mash_field_ops, row)])
                parsed = MashRow(*row)
                mash_rows.append(parsed)
        return mash_rows



if __name__=="__main__":
    MashScreen(sys.argv[1], sys.argv[2])
