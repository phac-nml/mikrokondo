/*
Standalone workflow to create a minimap2 index from some input sequences so that the user can create
an index on the fly
*/

include { MINIMAP2_INDEX } from "../../modules/local/minimap2_index.nf"

workflow CreateFilteringIndex {
    // TODO test this workflows creationg ability
    main:
    ch_fasta_dir = Channel.fromPath("${params.input}/*.{fa,fasta}") //input is a directory of .fa or .fasta files catted together
    MINIMAP2_INDEX(ch_fasta_dir.map {
        it -> tuple(["id": params.output_idx_name], it)
    })
    MINIMAP2_INDEX.out.index.copyTo(params.output_dir);
}
