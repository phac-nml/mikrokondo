/*Metagenomic samples are split based on their classification, using kraken2 and classified contigs.

2023-07-27: Matthew Wells
*/
include { BIN_KRAKEN2 } from '../../modules/local/bin_kraken2.nf'
include { KRAKEN } from '../../modules/local/kraken.nf'




workflow SPLIT_METAGENOMIC {
    // TODO seek clarity on whether reads should be merged back in as they are un seperated
    take:
    contigs // channel meta, contigs, reads

    main:
    // TODO create threshold for number of contigs that must belong to a group before being subset
    CREATE_META_RETURN_SIZE = 2
    versions = Channel.empty()
    ch_seperated_data = Channel.empty()


    contigs.subscribe {
        log.info "Splitting sample ${it[0].id} as sample was found to be metagenomic" // it[0] is where the meta field lives and should always be
    }

    contigs = contigs.map{
        meta, contigs, reads -> tuple(meta, contigs)
    }
    kraken_out = KRAKEN(contigs, params.kraken.db ? file(params.kraken.db): Channel.empty())
    staged_kraken_data = kraken_out.classified_contigs.join(kraken_out.report).join(kraken_out.kraken_output)

    binned_data = BIN_KRAKEN2(staged_kraken_data, Channel.value(params.kraken_bin.taxonomic_level))

    outputs = binned_data.map{
        it -> create_meta_channels(it)
    }

    ch_seperated_data = outputs.flatten().collate(CREATE_META_RETURN_SIZE)


    emit:
    divided_contigs = ch_seperated_data
}

def create_meta_channels(List fasta_paths){
    /*split each binned sample into seperate entries
    */
    def output_list = []
    def meta = fasta_paths[0] // meta field lives at spot 1
    //def output_list = []
    def fasta_path_len = fasta_paths.size()
    def one_bin_len = 1
    //def new_meta = deepcopy(meta)
    // TODO check for empty value or out of bounds errors
    // ! TODO out of bounds error will occur if no classified contigs are produced

    if(!(fasta_paths[1] instanceof Collection)){
        output_list << [meta, file(fasta_paths[1])]
    }else{
        for (i in fasta_paths[1]){
            def new_meta = deepcopy(meta)
            new_meta.sample = meta.id
            new_meta.id = i.getSimpleName()
            output_list << [new_meta, file(i)]
            //output_list.mix(channel.of(tuple(new_meta, file(i))))
            ////test = channel.of(tuple(new_meta, file(i)))
            ////test.view()
        }
    }

    return output_list
    //return Channel.fromList(output_list)

}


def deepcopy(orig) {
    /*Deepcopy of hashmap from https://stackoverflow.com/questions/13155127/deep-copy-map-in-groovy
    */
    bos = new ByteArrayOutputStream()
    oos = new ObjectOutputStream(bos)
    oos.writeObject(orig); oos.flush()
    bin = new ByteArrayInputStream(bos.toByteArray())
    ois = new ObjectInputStream(bin)
    return ois.readObject()
}
