#! /usr/bin/env python
"""Handle duplicate fastq sequences from nanopore runs

2023-06-15: Matthew Wells
"""
from typing import NamedTuple, List
import os
import sys
import gzip


class Fastq(NamedTuple):
    name: str
    sequence: str
    quality: str
    length : int

class RMDups:
    """Remove duplicate fastq's from oxford nanopore sequencing runs.

    If a sequence header is duplicated, the longest sequence will be kept.

    In the event of ties, that do not match the first sequence encountered will be kept
    TODO perhaps an average quality per a base score would be a good metric
    or even add an Identifier to the read
    """
    __gzipped_ext = frozenset(["gz", "gzip"])

    _gzip_reader = lambda self, y: gzip.open(y, 'rt')
    _std_reader = lambda self, y: open(y, 'r')

    # 33 is the 0 for fastq quality scores and chr gets their ascii values
    # TODO can use just an offset of 33
    #__q_scores = {chr(k): k-33 for k in range(33, 74)}
    __phred_offset = 33
    def __init__(self, fp) -> None:
        self.fp = fp
        self.file_reader = self.is_gzipped(self.fp)
        self.fastq_data = self.read_file(self.file_reader, self.fp)
        self.write_fastqs(self._print_seq, self.fastq_data)

    def write_fastqs(self, handler, data):
        """Write fastq files back out

        Args:
            handler (_type_): Function returning a singular result for each fastq value
            data (_type_): _description_
        """
        for k, v in data.items():
            if len(v) > 1:
                handler(v)
            #else:
            # Logic for printing a seqeunce here


    def _print_seq(self, sequence: List[Fastq]):
        print(sequence)

    def best_avg_length(self, sequence: List[Fastq]):
        """Pick the best sequence based on the best average base quality

        Args:
            sequence (List[Fastq]): _description_

        Returns:
            _type_: _description_
        """
        avg_quals = []
        for k, v in enumerate(sequence):
            # // qual_sum = sum([self.__q_scores[i] for i in v.quality[:-1]]) # leave out line ending character
            qual_sum = sum([ord(i) - self.__phred_offset for i in v.quality[:-1]]) # leave out line ending character
            avg_quals.append((k, qual_sum/v.length))
        highest_qual = max(avg_quals, key=lambda x: x[1])
        return sequence[highest_qual[0]] # return the seqeunce with the highest average base quality


    def best_length(self, sequence: List[Fastq]):
        """Pick the best match depending on best sequence match

        Args:
            sequence (Fastq): _description_
        """
        return max(sequence, key=lambda x: x.length)

    def read_file(self, handler, fp):
        """Read all lines from a file

        Args:
            handler (_type_): _description_
        """
        fastq_data = dict()
        with handler(fp) as file:
            lines = file.readlines()
            for k in range(0, len(lines), 4):
                # skipping the '+' sign, hence no lines[k+2] is listed
                sequence = lines[k+1]
                quality = lines[k+3]
                sequence_len = len(sequence)
                quality_len = len(quality)
                if sequence_len != quality_len:
                    sys.stderr.write(f"Read: {lines[k].strip()} had unequal quality and sequences lengths discarding\n")
                    continue
                fastq = Fastq(lines[k], lines[k+1], lines[k+3], sequence_len)
                if fastq_data.get(fastq.name) is None:
                    fastq_data[fastq.name] = []
                fastq_data[fastq.name].append(fastq)
        return fastq_data


    def is_gzipped(self, fp):
        """Test for if a file is gzipped

        Args:
            fp (_type_): _description_
        """
        if fp[fp.rindex(".")+1:] in self.__gzipped_ext:
            return self._gzip_reader
        return self._std_reader

class AppendDups(RMDups):
    """Append a line index to the fastq header to incase of duplicated fastq's
    TODO add in count of if Read ID's are duplicated
    TODO check that fastq file is mode of 4
    """
    def __init__(self, fp) -> None:
        self.fp = fp
        self.file_reader = self.is_gzipped(self.fp)
        self.fastq_data = self.read_file(self.file_reader, self.fp)

    def read_file(self, handler, fp):
        idx = 0
        with handler(fp) as file:
            for i in file:
                header = i
                new_header = header.replace(' ', f'_{idx} ', 1) if ' ' in header else header.replace("\n", f"_{idx}\n")
                sequence = next(file)
                plus = next(file)
                quality = next(file)
                if len(sequence) != len(quality):
                    sys.stderr.write(f"[Discarding Read] Sequence and quality length differ for {header}")
                    continue
                sys.stdout.write(f"{new_header}{sequence}{plus}{quality}") # append a tag to the first value of the read id
                idx += 1


if __name__=="__main__":
    AppendDups(sys.argv[1])
