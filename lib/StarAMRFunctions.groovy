


class StarAMRFunctions{
  static def staramr_arg_builder(java.util.Map qc_params){
    def staramr_arguments = [
        ["--genome-size-lower-bound", "staramr_genome_size_lower_bound"],
        ["--genome-size-upper-bound", "staramr_genome_size_upper_bound"],
        ["--percent-length-overlap-resfinder", "staramr_percent_length_overlap_resfinder"],
        ["--percent-length-overlap-pointfinder", "staramr_percent_length_overlap_pointfinder"]
    ]
    def output_args = []
    for(i in staramr_arguments){
            def identified_value = qc_params[i[0]] // returns null if does not exist
            if(identified_value){
                output_args << i[0]
                output_args << identified_value
            }
        }
    return output_args.join(' ')

  }
}
