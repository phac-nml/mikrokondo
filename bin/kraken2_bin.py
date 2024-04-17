#! /usr/bin/env python
"""Bin sequences classified by kraken into their appropriate groups base on a predefined taxonomic
level.

TODO add in flag checking for taxonomic level
TODO add in option to not copy out parent info
TODO add in option to do more with unclassified contigs

2023-06-08: Matthew Wells
"""
from typing import List, NamedTuple
from dataclasses import dataclass
from collections import defaultdict
import os
import sys


kraken2_classifiers = frozenset(["U", "R", "D", "K", "P", "C", "O", "F", "G", "S"])


class Kraken2Report:
    """Ingest kraken report

    Returns:
        _type_: _description_
    """

    __max_taxa_len = 40

    def __init__(self, fp, output_fp, tax_level, keep_children):
        # TODO add in script to seperate at a taxonmomic level
        self.fp = fp
        self.output_fp = output_fp
        self.tax_level = tax_level
        self.keep_children = keep_children
        self.report = self._parse_report(self.fp)
        self.output = self._parse_output(self.output_fp)
        self._graph = self._create_graph(self.report)
        self.bins = self.create_groups(self._graph, tax_level)

    @dataclass()  # not using slots=True as many people are using an old python
    class TaxID:
        """Class to hold the class ID's for all parents and children of a given taxid

        Returns:
            _type_: _description_
        """

        __slots__ = ("parents", "children")
        parents: List[int]
        children: dataclass  # to be the Node class

    @dataclass()  # not using slots=True as many people are using an old python
    class ReportRows:
        __slots__ = (
            "PercentId",
            "FragmentsRecovered",
            "FragmentsAssignmentTaxon",
            "RankCode",
            "ncbi",
            "SciName",
            "taxa",
        )
        PercentId: float
        FragmentsRecovered: int
        FragmentsAssignmentTaxon: int
        RankCode: str
        ncbi: int
        SciName: str
        taxa: List[str]

        def __init__(self, *args):
            self.PercentId = float(args[0])
            self.FragmentsRecovered = int(args[1])
            self.FragmentsAssignmentTaxon = int(args[2])
            self.RankCode = args[3]
            self.ncbi = int(args[4])
            self.SciName = args[5]

    class Node(NamedTuple):
        children: dict
        data: dataclass

    @dataclass()  # not using slots=True as many people are using an old python
    class Output:
        __slots__ = ("classified", "name", "tax_id", "length", "lca_list")
        classified: bool
        name: str
        tax_id: int
        length: int
        lca_list: list  # values are taxid:kmers_mapped

        def __init__(self, *args):
            self.classified = True if args[0] == "C" else False
            self.name = args[1]
            self.tax_id = int(args[2])
            self.length = int(args[3])
            self.lca_list = args[4].split(
                " "
            )  # the list is a path, showing sequentially X num kmers to one place than another

    def alternate_lca(self, output: List[Output]):
        """Determine alternate lowest common ancestors from the kraken2 output

        TODO this will not work on paired end data yet, as the output for that is delimited with a |:|

        Args:
            output (List[Output]): _description_
        """
        for i in output:
            values = [tuple(k.split(":")) for k in i.lca_list]
            print(i.length, i.tax_id, values)

    def _parse_output(self, fp):
        """Parse the kraken2 output

        Args:
            Self (_type_): _description_
            fp (_type_): _description_
        """
        entries = []
        with open(fp, "r", encoding="utf8") as file:
            for i in file.readlines():
                entries.append(self.Output(*i.strip().split("\t")))
        return entries

    def create_groups(self, graph, taxa_level):
        """Create tax_id groups/bins based on a provided taxonomic level

        Algorithm:  1) Traverse down a path gathering up all tax-ids for a given set (DFS)
                    2) When the given taxa_level is encountered, gather all tax-ids of the children below
                        - This is repeated for all nodes at the encountered depth of a given taxa level
                        - if it is determined some nodes go deeper this gets repeated

        Overview of DFS as I am tired and need to be very verbose with my logic:
            1) requires list of visited nodes, and a queue so I can get back up through the nodes

        Args:
            graph (_type_): _description_
            taxa_level (_type_): _description_
        """
        temp = graph
        to_visit = [temp]
        path = set()
        children_gather = []

        while to_visit and (node := to_visit.pop()):
            children = node.children
            for i in children:
                if i not in path:
                    if children[i].data.RankCode == taxa_level:
                        children_gather.append(children[i])
                    to_visit.append(node.children[i])
                path.add(i)
        bins = dict()
        for j in children_gather:
            bins[j.data.SciName.strip().replace(" ", "_")] = self.gather_parents_children(graph, j)
        return bins

    def gather_parents_children(self, graph, child):
        """Gather up all taxids and those of the parents
        TODO refactor above code to be generic to this problem

        Args:
            graph (_type_): _description_
            ids (_type_): _description_
        """
        temp = graph
        taxids = []
        if self.keep_children:
            for i in child.data.taxa:  # get all parents associated with the child
                taxids.append(temp.data)
                temp = temp.children[i]

        taxids.append(child.data)
        to_visit = [child]
        while to_visit and (node := to_visit.pop()):
            children = node.children
            for i in children:
                to_visit.append(children[i])
                taxids.append(children[i].data)
        return [i.ncbi for i in taxids]

    def graph_traversal(self, graph: Node):
        """Traverse through the kraken2 graph data

        Args:
            graph (_type_): _description_
        """

        temp = graph
        to_visit = [temp]
        try:
            while node := to_visit.pop():
                for i in node.children:
                    for j in node.children[i].data:
                        # print(",".join(j.taxa), j.FragmentsRecovered)
                        print(j.RankCode, j.FragmentsRecovered)
                    to_visit.append(node.children[i])
        except IndexError:
            pass

    def create_bins(self, report_data: List[ReportRows], tax_level: str):
        """Create bins at a defined taxonomic level

        Args:
            report_data (List[ReportRows]): _description_
        """
        bins = defaultdict(set)  # key: parent_tax_id (specified level), value is a set of said taxid in that bin
        idx = 0
        bin_key = None
        report_data_len = len(report_data)
        while idx < report_data_len:
            if report_data[idx].RankCode == tax_level:
                bin_key = report_data[idx].SciName
                idx += 1
                bins[bin_key].add(bin_key)
                while idx < report_data_len and report_data[idx].RankCode != tax_level:
                    bins[bin_key].add(report_data[idx].ncbi)
                    idx += 1
                idx -= 1
            idx += 1
        # check last entry
        if report_data[report_data_len - 1].RankCode == tax_level:
            bins[report_data[report_data_len - 1].SciName].add(report_data[report_data_len - 1].ncbi)
        else:
            bins[bin_key].add(report_data[report_data_len - 1].ncbi)
        # TODO upgrade this to be used in union find data structure
        return bins

    def _parse_report(self, fp) -> List[ReportRows]:
        """Read and parse the kraken2 report file
        TODO check correct branches are being made
        Args:
            fp (_type_): _description_

        Returns:
            _type_: _description_
        """
        report_rows = []
        taxon_rows = [
            None for _ in range(self.__max_taxa_len)
        ]  # to contain the position of the last entry of each sample
        idx = 0
        with open(fp, "r", encoding="utf8") as file:
            previous_line_len = 0
            for line in file.readlines():
                idx += 1
                new_row = self.ReportRows(*line.strip().split("\t"))
                split_taxa = new_row.SciName.split("  ")
                last_value = len(split_taxa) - 1

                if last_value >= self.__max_taxa_len:
                    taxon_rows.append(
                        None
                    )  # the way the file is organized, only one sample is needed to be added at a time
                    self.__max_taxa_len += 1

                if last_value < previous_line_len:
                    k = last_value
                    while k < self.__max_taxa_len:
                        taxon_rows[k] = None
                        k += 1
                previous_line_len = last_value
                taxon_rows[last_value] = (
                    new_row.RankCode + "__" + split_taxa[last_value]
                )  # create taxa string as in mpa report
                new_row.taxa = [i for i in taxon_rows[: last_value + 1]]  # construct a new list
                report_rows.append(new_row)
        return report_rows

    def _create_graph(self, report_info: List[ReportRows]):
        """Create a searchable graph from the ingested report info

        Args:
            report_info (_type_): _description_

        Returns:
            _type_: _description_
        """

        taxa_graph = self.Node(dict(), report_info[0])
        head = taxa_graph
        for i in report_info[1:]:
            node = taxa_graph
            for value in i.taxa:
                if not node.children.get(value):
                    node.children[value] = self.Node(dict(), i)
                node = node.children[value]

        return head


class FastaReader:
    """
    Parse a fasta file into its sequences and headers
    """

    @dataclass()
    class Fasta:
        __slots__ = ("header", "taxid", "sequence")
        header: str
        taxid: int
        sequence: str

    def __init__(self, fp):
        self.fp = fp
        self.sequences = self._parse_fasta(self.fp)

    def _parse_fasta(self, fp) -> List[Fasta]:
        """Read and parse a fasta file"""
        sequences = []
        with open(fp, "r", encoding="utf8") as fasta:
            header = None
            sequence = None
            taxid = None
            for line in fasta.readlines():
                if line.startswith(">"):
                    if header:
                        sequences.append(self.Fasta(header, taxid, "".join(sequence)))
                    header = line.strip()
                    taxid = int(header.split("|")[-1])
                    sequence = []
                elif header:
                    sequence.append(line.strip())
            if header:
                sequences.append(self.Fasta(header, taxid, "".join(sequence)))
        return sequences


class CreateBins:
    """Create the bins for each sequence
    TODO this is going to be slow at first, but in the future, the look up should use a different data structure as this linear
    lookup will be slow

    TODO Currently binning out on user defined level and discarding the higher up unclassified contigs
        - The plan is to figure out why kraken2 is not classifying reads lower
        - Add in an option to copy out the higher level core data into the smaller files generated
            - This will be a next week problem, as it requires a different data structure

    """

    def __init__(self, report_fp, output_fp, fasta_fp, taxa_level, keep_parents):
        self.report_data = Kraken2Report(report_fp, output_fp, taxa_level, keep_parents)
        self.bins = self.report_data.bins
        self.fastas = FastaReader(fasta_fp).sequences
        self.data_bin = self.bin_data(self.bins, self.fastas)
        self.write_fastas(self.data_bin)

    def write_fastas(self, sequences):
        """write each set of sequences to a containing a defined taxa level

        Args:
            sequences (_type_): _description_
        """
        for k, v in sequences.items():
            with open(
                f"{k.strip().replace(' ', '_').replace('(', '_').replace(')', '_').replace('.', '_')}.binned.fasta",
                "w",
                encoding="utf8",
            ) as out_file:
                out_file.write("\n".join(v))
                out_file.write("\n")

    def bin_data(self, bins, fasta):
        """_summary_

        Args:
            bins (_type_): _description_
            fasta (_type_): _description_

        Returns:
            _type_: _description_
        """
        output_files = defaultdict(list)  # output files, key
        for i in fasta:
            # slow look up of bins
            for key, value in bins.items():
                if i.taxid in value:
                    output_files[key].append(i.header)
                    output_files[key].append(i.sequence)
                    break
        return output_files


if __name__ == "__main__":
    # FastaReader(sys.argv[1])
    # Kraken2Report(sys.argv[1], sys.argv[2], "S")
    try:
        taxonomic_level = sys.argv[4].upper()
    except IndexError:
        sys.stderr.write(f"No taxonomic limit specified, please choose one of the following.\n")
        sys.stderr.write(f"Please choose on of the following: {' '.join([i for i in kraken2_classifiers])} \n")
        sys.exit(-1)

    if taxonomic_level not in kraken2_classifiers:
        sys.stderr.write(f"{taxonomic_level} is not classification option.\n")
        sys.stderr.write(f"Please choose on of the following. {' '.join([i for i in kraken2_classifiers])} \n")
        sys.exit(-1)
    CreateBins(sys.argv[1], sys.argv[2], sys.argv[3], taxonomic_level, keep_parents=False)
