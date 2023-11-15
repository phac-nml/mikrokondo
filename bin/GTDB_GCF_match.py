"""Match up GTDB taxonomy data to assembly paths

    TODO cmd line outputs work quite nicely in bash, but this kind of scatter gather process will fit into
    nextflow nicely and help apply caps to processes run at a time
"""
import os
import io
import sys


class PasteyMcPasteFace:
    """Great stuff :D

    Returns:
        _type_: _description_
    """

    ...


class AssemblyPaths:
    """Take in a file of assemblies and parse out the assembly prefix"""

    _rs_gb_delimiter = "_"
    _gcf_gca_delimiter = "_"
    _search_prefix = "GCF"
    _search_pre_len = len(_search_prefix)

    def __init__(self, fp_assembly_path, fp_taxa_info):
        self.file_exist(fp_assembly_path)
        self.file_exist(fp_taxa_info)

        self.taxa_info = fp_taxa_info
        self.fp = fp_assembly_path
        self.file_names = self.parse_assembly_name()
        self.taxa = self.taxon_info()
        self.records = len(self.file_names)
        self.merge_taxa_info()
        self.filtered_output = self.remove_missing_taxa_info()
        self.save_outputs()

    def save_outputs(self):
        """write multiple output files for mash sketch

        Mash seems to need labels passed to the CLI for each sequence to sketch so now the samples are being used to create cli commands
        """
        id_data = open("mash_cli.txt", "w", encoding="utf8")
        # path_data = open("mash_paths.txt", "w", encoding='utf8')
        # taxa_data = open("mash_taxa.txt", "w", encoding='utf8')
        for k, v in self.filtered_output.items():
            id_data.write(f"\"{v[0]}\" -I '{k}' -C '{v[1]}'\n")
            # path_data.write(f"{v[0]}\n")
            # taxa_data.write(f"{v[1]}\n")

        id_data.close()
        # path_data.close()
        # taxa_data.close()

    def remove_missing_taxa_info(self):
        """remove dictionary entries with missing taxa info"""
        keys_rm = set()
        for k, v in self.file_names.items():
            if len(v) == 1:
                keys_rm.add(k)
        len_keys_rm = len(keys_rm)
        out_str = f"Missing taxon data for {len_keys_rm} assemblies ({round(((len_keys_rm / len(self.file_names)) * 100), 2)} of assemblies)%. Removing them from output.\n"
        sys.stderr.write(out_str)
        new_dict = {k: v for k, v in self.file_names.items() if k not in keys_rm}
        return new_dict

    def merge_taxa_info(self):
        """merge the taxa data and the assembly paths

        Returns:
            _type_: _description_
        """
        for i in self.taxa:
            if self._search_prefix != i[0][0 : self._search_pre_len]:
                continue
            if self.file_names.get(i[0]):
                self.file_names[i[0]].append(i[1])

    @staticmethod
    def file_exist(file_in):
        """Check if file exists

        Args:
            file_in (_type_): input file path to check for existence
        """
        if not os.path.isfile(file_in):
            print(f"Assemblies paths do not exist at {file_in}")
            sys.exit(-1)

    def taxon_info(self):
        """Parse assembly name and taxa info"""
        out_list = []
        with open(self.taxa_info, "r", encoding="utf8") as taxa:
            for i in taxa.readlines():
                split_line = i.strip().split("\t")
                # split at first under score as gtdb appends weather source is refseq or genbank
                name = split_line[0][split_line[0].index(self._rs_gb_delimiter) + 1 :]
                out_list.append((name, split_line[1]))

        return out_list

    def parse_assembly_name(self):
        """
        read and parse all entries
        """
        with open(self.fp, "r", encoding="utf8") as file_in:
            # all file names are delimited from tail at second underscore
            # lines = map(lambda x: (os.path.basename(x[:x.rindex("_")]), x.strip()), file_in.readlines())
            # lines = [(os.path.basename(x[:x.rindex(self._gcf_gca_delimiter)]), x.strip()) for x in  file_in.readlines()]
            lines = {os.path.basename(x[: x.rindex(self._gcf_gca_delimiter)]): [x.strip()] for x in file_in.readlines()}
        return lines


if __name__ == "__main__":
    AssemblyPaths(sys.argv[1], sys.argv[2])
