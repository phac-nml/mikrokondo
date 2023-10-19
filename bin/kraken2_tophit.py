#! /usr/bin/env python
"""Identify the top-hit of a sample based on is kraken report

TODO have ties return a null result
Matthew Wells: 2023-08-28
"""
from typing import NamedTuple
from dataclasses import dataclass
from collections import defaultdict
import sys



KRAKEN2_CLASSIFIERS = frozenset(["U", "R", "D", "K", "P", "C", "O", "F", "G", "S"])


@dataclass()# not using slots=True as many people are using an old python
class ReportRows:
    __slots__ = ("PercentId", "FragmentsRecovered", "FragmentsAssignmentTaxon", "RankCode", "ncbi", "SciName")
    PercentId: float
    FragmentsRecovered: int
    FragmentsAssignmentTaxon: int
    RankCode: str
    ncbi: int
    SciName: str

    def __init__(self, *args):
        self.PercentId = float(args[0])
        self.FragmentsRecovered = int(args[1])
        self.FragmentsAssignmentTaxon = int(args[2])
        self.RankCode = args[3]
        self.ncbi = int(args[4])
        self.SciName = args[5].strip()

    def __key(self):
        return (self.PercentId, self.ncbi, self.SciName)

    def __hash__(self) -> int:
        return hash(self.__key())

    def __eq__(self, other):
        if isinstance(other, ReportRows):
            return self.__key() == other.__key()
        return NotImplemented

class Kraken2Tophit:
    """Alternate implementation of the kraken2 report class

    This class has been re-implemented as I bloated the object in the binning script and
    it is currently faster to implement the report parsing script separately.

    TODO See if this functionality can fit into a refactor of the kraken2_bin.py script
    """
    _delimiter = "\t"

    def __init__(self, report, taxa_level) -> None:
        self.report = report
        self.taxa_level = taxa_level
        self.report_levels = self.read_report(self.report)
        self.selected_taxa =  self.report_levels.get(taxa_level)
        if self.selected_taxa is None:
            sys.stderr.write(f"Could not find taxa level {self.taxa_level} in output\n")
            sys.exit(-1)
        self.top_hit = self.select_top_hit(list(self.selected_taxa))
        sys.stdout.write(f"{self.top_hit.SciName.replace('"', '')}")

    def select_top_hit(self, taxa_row: list):
        """Pick the top hit of the selected data

        Args:
            taxa_row (_type_): _description_
        """
        taxa_row.sort(reverse=True, key=lambda x: x.PercentId)
        output = "No Species Identified"
        if taxa_row: # list has objects
            output = taxa_row[0]
        return output

    def read_report(self, report):
        report_levels = defaultdict(lambda: set())
        with open(report, "r", encoding="utf8") as k_report:
            for line in k_report.readlines():
                report_row = ReportRows(*line.strip().split("\t"))
                report_levels[report_row.RankCode].add(report_row)
        return report_levels





if __name__=="__main__":
    try:
        taxonomic_level = sys.argv[2].upper()
    except IndexError:
        sys.stderr.write(f"No taxonomic limit specified, please choose one of the following.\n")
        sys.stderr.write(f"Please choose on of the following: {' '.join([i for i in KRAKEN2_CLASSIFIERS])} \n")
        sys.exit(-1)

    if taxonomic_level not in KRAKEN2_CLASSIFIERS:
        sys.stderr.write(f"{taxonomic_level} is not classification option.\n")
        sys.stderr.write(f"Please choose on of the following. {' '.join([i for i in KRAKEN2_CLASSIFIERS])} \n")
        sys.exit(-1)

    Kraken2Tophit(sys.argv[1], taxonomic_level)
