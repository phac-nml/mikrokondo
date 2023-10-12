#! /usr/bin/env python
"""Generate summary FastQ stats in a way that fits neatly into Nextflow
e.g. no C or external dependencies :(

FYI, This is very slow, partly because it is python partly because a
large focus has been placed on precision. hopefully this can be replaced later


2023-09-07: Matthew Wells
"""
from dataclasses import dataclass, asdict
from typing import Union
from timeit import default_timer as timer
import argparse
import json
import statistics
import decimal
import sys
import os
import gzip

#decimal.getcontext().prec = 4

@dataclass
class FastqQaul:
    __slots__ = ["total_bp", "total_reads", "qual_min",
                "qual_max", "qual_sum", "qual_mean", "qual_std", "read_qual_mean",
                "read_qual_std", "mean_sequence_length", "min_sequence_length",
                "max_sequence_length", "std_sequence_length"]
    total_bp: int
    total_reads: int
    qual_min: Union[float, decimal.Decimal]
    qual_max: Union[float, decimal.Decimal]
    qual_sum: int
    qual_mean: Union[float, decimal.Decimal]
    qual_std: Union[float, decimal.Decimal]
    read_qual_mean: Union[float, decimal.Decimal]
    read_qual_std: Union[float, decimal.Decimal]
    mean_sequence_length: Union[float, decimal.Decimal]
    min_sequence_length: Union[float, decimal.Decimal]
    max_sequence_length: Union[float, decimal.Decimal]
    std_sequence_length: Union[float, decimal.Decimal]

    #def __repr__(self):
    #    # TODO just call asdict on output
    #    repr_val = "\n\t{" + f"""
    #    \t\ttotal_bp: {self.total_bp},
    #    \t\ttotal_reads: {self.total_reads},
    #    \t\tqual_min: {int(self.qual_min)},
    #    \t\tqual_max: {int(self.qual_max)},
    #    \t\tqual_sum: {int(self.qual_sum)},
    #    \t\tqual_mean: {round(self.qual_mean, 2)},
    #    \t\tqual_std: {round(self.qual_std, 2)},
    #    \t\tread_qual_mean: {round(self.read_qual_mean, 2)},
    #    \t\tread_qual_std: {round(self.read_qual_std, 2)},
    #    \t\tmean_sequence_length: {round(self.mean_sequence_length, 2)},
    #    \t\tstd_sequence_length: {round(self.mean_sequence_length, 2)},
    #    \t\tmin_sequence_length: {int(self.min_sequence_length)},
    #    \t\tmax_sequence_length: {int(self.max_sequence_length)},
    #    """ +"\t}\n"
    #    return repr_val



class FastQReader:
    """A slow but accurate program for calculating simple fastq metrics

    Returns:
        _type_: _description_
    """

    __gzip_extensions = frozenset([".GZ", ".GZIP"])
    __fq_extensions = frozenset([".FASTQ", ".FQ"])

    _gzip_reader = lambda self, y: gzip.open(y, 'rt')
    _std_reader = lambda self, y: open(y, 'r')
    phred_offset = 33
    __round = lambda self, x: round(x, 2)


    def __init__(self, files, names=None, high_precision=False) -> None:
        sys.stderr.write(f"High precision mode: {high_precision}\n")
        if not high_precision:
            self.mean_calc = statistics.fmean
            self.conversion = float
        else:
            self.mean_calc = statistics.mean
            self.conversion = decimal.Decimal

        if not len(files):
            sys.stderr.write("No files specified\n")
            sys.exit(1)

        if names is None:
            names = [None for _ in range(len(files))]

        self.file_data = dict()
        self.total_bp = 0
        self.read_len = []
        self.read_avg_qual = []
        self.qual_scores = []
        for i, j in zip(files, names):
            self.read_file(i, j)
        self.create_combined_data()
        print(json.dumps(self.file_data, indent=2))

    def create_combined_data(self):
        sys.stderr.write(f"Calculating combined metrics.\n")
        start = timer()
        total_read_mean_len, total_read_std_len = self.calc_mean_stdev(self.read_len)
        total_qual_mean, total_qual_std = self.calc_mean_stdev(self.qual_scores)
        total_read_qual_mean, total_read_qual_std = self.calc_mean_stdev(self.read_avg_qual)
        end = timer()
        sys.stderr.write(f"Calculating combined metrics took: {round(end - start, 2)} seconds\n")
        self.file_data["combined"] = asdict(FastqQaul(
            total_bp=self.total_bp,
            total_reads=len(self.read_len),
            qual_min=min(self.qual_scores),
            qual_max=max(self.qual_scores),
            qual_mean=self.__round(total_qual_mean),
            qual_std=self.__round(total_qual_std),
            qual_sum=sum(self.qual_scores),
            mean_sequence_length=self.__round(total_read_mean_len),
            std_sequence_length=self.__round(total_read_std_len),
            min_sequence_length=min(self.read_len),
            max_sequence_length=max(self.read_len),
            read_qual_mean=self.__round(total_read_qual_mean),
            read_qual_std=self.__round(total_read_qual_std)
        ))

    def verify_fastq(self, file, header, sequence, plus, quality):
        if not header.startswith("@"):
            sys.stderr.write(f"Fastq Header is incorrect in: {file}\n")
            sys.exit(1)
        if not (sequence and quality) or (len(sequence) != len(quality)):
            sys.stderr.write(f"Fastq sequence and quality information incorrect in : {file}\n")
            sys.exit(1)
        if not plus:
            sys.stderr.write(f"Mangled fastq entry, missing '+' in {file}\n")
            sys.exit(1)


    def read_file(self, file, name=None):
        self.validate_file(file)
        reader = self.get_file_reader(file)
        key_name = name
        if key_name is None:
            key_name = os.path.basename(file)
        total_bp = 0
        read_len = []
        read_avg_qual = []
        qual_scores = []
        with reader(file) as text:
            for i in text:
                try:
                    header = i.strip()
                    sequence = next(text).strip()
                    plus = next(text).strip()
                    quality = next(text).strip()
                except StopIteration:
                    pass
                else:
                    self.verify_fastq(file, header, sequence, plus, quality)
                    seq_len = len(sequence)
                    total_bp += seq_len
                    read_len.append(seq_len)
                    qual_conversion = [ord(x) - self.phred_offset for x in quality]
                    qual_scores.extend(qual_conversion)
                    qual_sum = sum(qual_conversion)
                    avg_qual_read = self.conversion(qual_sum) / self.conversion(seq_len)
                    read_avg_qual.append(avg_qual_read)
        sys.stderr.write(f"Finished reading: {file}, creating summary statistics\n")
        start = timer()
        read_mean_length, read_std_len = self.calc_mean_stdev(read_len)
        qual_mean, qual_std = self.calc_mean_stdev(qual_scores)
        read_qual_mean, read_qual_std = self.calc_mean_stdev(read_avg_qual)

        self.total_bp += total_bp
        self.read_len.extend(read_len)
        self.read_avg_qual.extend(read_avg_qual)
        self.qual_scores.extend(qual_scores)
        end = timer()
        sys.stderr.write(f"Gathering summary metrics for {file} took: {round(end - start, 2)} seconds\n")

        self.file_data[key_name] = asdict(FastqQaul(total_bp=total_bp,
                        total_reads=len(read_avg_qual),
                        qual_min=min(qual_scores),
                        qual_max=max(qual_scores),
                        qual_mean=self.__round(qual_mean),
                        qual_std=self.__round(qual_std),
                        qual_sum=sum(qual_scores),
                        mean_sequence_length=self.__round(read_mean_length),
                        std_sequence_length=self.__round(read_std_len),
                        min_sequence_length=min(read_len),
                        max_sequence_length=max(read_len),
                        read_qual_mean=self.__round(read_qual_mean),
                        read_qual_std=self.__round(read_qual_std)))


    def calc_mean_stdev(self, list_vals):
        mean = self.mean_calc(list_vals)
        stdev = statistics.stdev(list_vals, mean)
        return mean, stdev


    def get_file_reader(self, file):
        ext = os.path.splitext(file)[-1].upper()
        if ext in self.__gzip_extensions:
            return self._gzip_reader
        if ext in self.__fq_extensions:
            return self._std_reader
        else:
            sys.stderr.write(f"File extension {ext} is not recognized\n")
            sys.exit(1)


    def validate_file(self, fp):
        if os.path.isfile(fp):
            return True
        else:
            sys.stderr.write(f"Could not find file: {fp}\n")
            sys.exit(1)

def str2bool(val):
    if isinstance(val, bool):
        return val
    if val.lower() in frozenset(["yes", "true", "1", 'y', 't']):
        return True
    elif val.lower() in frozenset(["false", "f", "no", '0']):
        return False
    else:
        raise argparse.ArgumentTypeError(f"Could not discern truth value of {val}")

def args_in():
    parser = argparse.ArgumentParser(
        prog="RawReadStats",
        description="Tabulate raw read stats of file",
    )

    parser.add_argument("-f", "--files", nargs="+",
                        help="Specify all files to be processes", required=True)
    parser.add_argument("-n", "--names",
                        help="List of alternate names to provide the files, must match order of inputs", nargs="+")
    parser.add_argument("-p", "--high-precision",
                        help="Enable high precision arithmetic", default=False, type=str2bool)
    args_out = parser.parse_args()
    return args_out


if __name__ == "__main__":
    args = args_in()
    FastQReader(args.files, args.names, args.high_precision)
