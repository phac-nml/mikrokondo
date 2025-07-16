#! /usr/bin/env python

"""Generate summary FastQ stats in a way that fits neatly into Nextflow
e.g. no C or external dependencies :(


2025-07-08: Matthew Wells
"""
from functools import partial
from collections import defaultdict
import math
import typing as t
import gzip
import io
import pathlib as p
import argparse
import json
import decimal
import sys
import os


GZIP_MAGIC_NUMBERS = b"\x1f\x8b"
FQ_EXTENSIONSj = frozenset([".FASTQ", ".FQ"])

GZIP_READER = partial(gzip.open, mode="rt")
STD_READER = partial(open, mode="r")

EXPECTED_LINES_IN_FASTQ = 4


def get_file_reader(file: p.Path) -> io.StringIO:
    """
    Return a text stream based on a files encoding. File is assumed to be plaintext
    unless there is information showing that it is compressed. As the FastQ format
    will be validated downstream as it is not easy determining if a file is
    plaintext or binary.
    """

    f_reader = STD_READER
    with open(file, "rb") as test_f:
        test_bytes = test_f.read(2)
        if test_bytes == GZIP_MAGIC_NUMBERS:
            f_reader = GZIP_READER
    return f_reader(file)


class FastQData:
    """
    This object is used for tracking FastQ data from a file as
    it is read. Counters are stored of quality data in the form of a
    bit vector as the number of times an observation is seen can be tracked.

    Sequence lenghts will be tracked as a dictionary with counts denoting a given
    read size, this will prevent the need of using an exceedingly large list from
    being kept. In reality this could be kept in a BST
    """

    __phred_values = 93  # Number of phred values possible
    __phred_offset = 33
    _round = lambda self, x: round(x, 2)

    def __init__(
        self, name: str, numeric_conversion: t.Callable[[int], float | decimal.Decimal]
    ):
        self.name = name
        self.total_reads: int = 0
        self.total_bp: int = 0
        self.qual_sum: int = 0
        self.qual_max: int = 0
        self.qual_min: int = 0
        self.qual_mean: None | float | decimal.Decimal = None
        self.qual_std: None | float | decimal.Decimal = None
        self.read_qual_mean: None | float | decimal.Decimal = None
        self.read_qual_std: None | float | decimal.Decimal = None
        self.numeric_conversion = numeric_conversion
        self.quality: list[int] = [0] * self.__phred_values
        self.sequence_lengths: defaultdict[int, int] = defaultdict(lambda: 0)
        self.avg_qual_read: defaultdict[int, int] = defaultdict(lambda: 0)
        self.mean_sequence_length = None
        self.min_sequence_length = None
        self.max_sequence_length = None
        self.std_sequence_length = None

    def __add__(self, obj: "FastQData") -> "FastQData":
        """
        Combine two objects creating a combined one containing the
        required totals to create summary metrics
        """
        new_data = FastQData("combined", self.numeric_conversion)

        new_quality: list[int] = [
            self.quality[idx] + obj.quality[idx] for idx in range(self.__phred_values)
        ]

        sequence_lengths = self._combine_dictionaries(
            self.sequence_lengths, obj.sequence_lengths
        )
        avg_qual_read = self._combine_dictionaries(
            self.avg_qual_read, obj.avg_qual_read
        )

        new_data.quality = new_quality
        new_data.sequence_lengths = sequence_lengths
        new_data.avg_qual_read = avg_qual_read
        new_data.total_reads = self.total_reads + obj.total_reads
        new_data.total_bp = self.total_bp + obj.total_bp
        new_data.qual_sum = self.qual_sum + obj.qual_sum
        return new_data

    @staticmethod
    def _combine_dictionaries(d1, d2):
        """
        Combine two dictionaries summing the values of keys instead
        overwriting them.
        """

        new_dict = {**d1}
        for key, value in d2.items():
            if new_dict.get(key) is not None:
                new_dict[key] += value
            else:
                new_dict[key] = value
        return new_dict

    def _set_statistics(self):
        """
        Populate all metrics required to be reported
        """
        self.__set_read_length_metrics()
        self.__set_quality_metrics()
        self.__set_per_read_quality_metrics()

    def to_dict(self) -> dict[str, int | float | decimal.Decimal]:
        """
        Produce a dictionary of the final metrics to be reported.
        """
        self._set_statistics()
        data = {
            "total_bp": self.total_bp,
            "total_reads": self.total_reads,
            "qual_min": self.qual_min,
            "qual_max": self.qual_max,
            "qual_sum": self.qual_sum,
            "qual_mean": self._round(self.qual_mean),
            "qual_std": self._round(self.qual_std),
            "read_qual_mean": self._round(self.read_qual_mean),
            "read_qual_std": self._round(self.read_qual_std),
            "mean_sequence_length": self._round(self.mean_sequence_length),
            "min_sequence_length": self.min_sequence_length,
            "max_sequence_length": self.max_sequence_length,
            "std_sequence_length": self._round(self.std_sequence_length),
        }
        return data

    def __set_quality_metrics(self):
        """
        Set the quality metrics required for the sample.
        """

        self.__set_quality_min_max()
        self.__set_qual_mean()
        self.__set_qual_std()

    def __set_read_length_metrics(self):
        """
        Set the metrics required for reporting of read length.
        """
        mean, min_, max_ = self._calculate_mean_min_max(
            self.sequence_lengths, self.total_reads
        )
        std = self._calculate_dict_std(self.sequence_lengths, mean, self.total_reads)
        self.mean_sequence_length = mean
        self.min_sequence_length = min_
        self.max_sequence_length = max_
        self.std_sequence_length = std

    def __set_per_read_quality_metrics(self):
        """
        Set the metrics required for quality per a read.
        """
        mean, min_, max_ = self._calculate_mean_min_max(
            self.avg_qual_read, self.total_reads
        )
        std = self._calculate_dict_std(self.avg_qual_read, mean, self.total_reads)
        self.read_qual_mean = mean
        self.read_qual_std = std

    def __set_quality_min_max(self):
        """
        Calculates Phred quality min and max.
        """
        min_idx = None
        max_idx = 0
        for k, v in enumerate(self.quality):
            if min_idx == None and v != 0:
                min_idx = k
            if v != 0:
                max_idx = k  # increment until the maximum quality value is found
        self.qual_min = min_idx
        self.qual_max = max_idx

    def _calculate_mean_min_max(
        self, vector: defaultdict[int, int], total: int
    ) -> float | decimal.Decimal:
        """
        Calculate the mean of a dictionary containing sequence information.
        """
        sum_ = 0
        min_length = float("inf")
        max_length = 0
        for key, value in vector.items():
            sum_ += key * value
            if key > max_length:
                max_length = key
            if key < min_length:
                min_length = key
        return (
            self.numeric_conversion(sum_) / self.numeric_conversion(total),
            min_length,
            max_length,
        )

    def _calculate_dict_std(
        self, vector: defaultdict[int, int], mean: float | decimal.Decimal, total: int
    ):
        """
        Calculate mean of a dictionary containing sequence information.
        """
        sum_of_squares = 0
        for key, value in vector.items():
            diff = key - mean
            diff_sq = math.pow(diff, 2)
            sum_of_squares += diff_sq * value
        normalized_squares = self.numeric_conversion(
            sum_of_squares
        ) / self.numeric_conversion(total)
        standard_deviation = math.sqrt(normalized_squares)
        return standard_deviation

    def __set_qual_std(self):
        """
        Calculate the standard deviation of the vector containing
        quality data.
        """
        qual_mean = self.qual_mean
        sum_of_squares = 0
        for key, value in enumerate(self.quality):
            if value != 0:
                diff = key - qual_mean
                diff_sq = math.pow(diff, 2)
                sum_of_squares += diff_sq * value
        normalized_squares = self.numeric_conversion(
            sum_of_squares
        ) / self.numeric_conversion(self.total_bp)
        standard_deviation = math.sqrt(normalized_squares)
        self.qual_std = standard_deviation

    def __set_qual_mean(self):
        """
        From a tuple of values calculate the mean, where the key is value and
        the second value is the frequency of it
        """
        self.qual_mean = self.numeric_conversion(
            self.qual_sum
        ) / self.numeric_conversion(self.total_bp)

    def _update_quality_vector(self, quality: str):
        """
        Updates the frequency of quality values in the classes
        quality array (self.quality) with the current reads information.
        """
        qual_sum = 0
        for x in quality:
            """
            Converts the quality character into is ascii phred value
            which is then used as an index in the quality vector.
            """

            idx = ord(x) - self.__phred_offset
            qual_sum += idx
            self.quality[idx] += 1
        read_average_quality = self.numeric_conversion(
            qual_sum
        ) / self.numeric_conversion(len(quality))
        self.avg_qual_read[read_average_quality] += 1
        self.qual_sum += qual_sum

    def add_record(self, sequence: str, quality: str):
        """
        Add a record to the FastQ reader
        """
        self.total_reads += 1
        self.total_bp += len(sequence)
        self._update_quality_vector(quality)
        self.sequence_lengths[len(sequence)] += 1


def str2bool(val):
    if isinstance(val, bool):
        return val
    if val.lower() in frozenset(["yes", "true", "1", "y", "t"]):
        return True
    elif val.lower() in frozenset(["false", "f", "no", "0"]):
        return False
    else:
        raise argparse.ArgumentTypeError(f"Could not discern truth value of {val}")


def verify_fastq(file, header, sequence, plus, quality):
    if not header.startswith("@"):
        sys.stderr.write(f"Fastq Header is incorrect in: {file}\n")
        sys.exit(1)
    if not (sequence and quality) or (len(sequence) != len(quality)):
        sys.stderr.write(
            f"Fastq sequence and quality information incorrect in : {file}\n"
        )
        sys.exit(1)
    if not plus:
        sys.stderr.write(f"Mangled fastq entry, missing '+' in {file}\n")
        sys.exit(1)


def decimal_serializer(obj):
    """
    High precision decimal numbers cannot be
    serialized as json. This function serves as a
    wrapper so that the the correct representation of
    the value is shown.
    """
    if isinstance(obj, decimal.Decimal):
        return float(
            obj
        )  # Value is already round so we should not see a large loss in precision
    return obj


def args_in():
    parser = argparse.ArgumentParser(
        prog="RawReadStats",
        description="Tabulate raw read stats of file",
    )

    parser.add_argument(
        "-f",
        "--files",
        nargs="+",
        help="Specify all files to be processes",
        required=True,
    )
    parser.add_argument(
        "-n",
        "--names",
        help="List of alternate names to provide the files, must match order of inputs",
        nargs="+",
    )
    parser.add_argument(
        "-p",
        "--high-precision",
        help="Enable high precision arithmetic",
        default=False,
        type=str2bool,
    )
    args_out = parser.parse_args()
    return args_out


if __name__ == "__main__":
    args = args_in()

    # Verify some files were passed in
    if not len(args.files):
        sys.stderr.write("No files specified\n")
        sys.exit(1)

    # Set names if none are provided
    names = args.names
    if args.names is None:
        names = [idx for idx in range(len(args.files))]

    # Set the function used for numeric percision
    numeric_conversion = float
    if args.high_precision:
        numeric_conversion = decimal.Decimal

    fq_data: dict[str, float | decimal.Decimal] = {}
    combined_data = FastQData("combined", numeric_conversion)
    for file, name in zip(args.files, names):
        file_p = p.Path(file)
        data = FastQData(name, numeric_conversion)
        with get_file_reader(file_p) as fastq:
            for line in fastq:
                lines_read = 0
                try:
                    header = line.strip()
                    lines_read += 1
                    sequence = next(fastq).strip()
                    lines_read += 1
                    plus = next(fastq).strip()
                    lines_read += 1
                    quality = next(fastq).strip()
                    lines_read += 1
                except StopIteration:
                    if lines_read != EXPECTED_LINES_IN_FASTQ:
                        sys.stderr.write(f"Missing fastq entry in: {file}\n")
                        sys.exit(1)
                    pass
                else:
                    verify_fastq(file, header, sequence, plus, quality)
                    data.add_record(sequence, quality)
        fq_data[data.name] = data.to_dict()
        combined_data += data
        sys.stderr.write(f"Finished reading file: {name}\n")

    fq_data[combined_data.name] = combined_data.to_dict()
    print(json.dumps(fq_data, indent=2, default=decimal_serializer))
