

class ReportFunctions {

    enum FuncType {

        GENERIC,
        CONTIG,
        READQUALITY,
        AUTOFAIL,
        COVERAGE

    }

    enum QCStatus{
        PASSED,
        FAILED,
        WARNING
    }


    static def metricFailed(java.util.LinkedHashMap qual_data, java.lang.String metric){
        return qual_data && qual_data.containsKey(metric) && qual_data[metric].containsKey("status") && !qual_data[metric].status
    }

    static def metricIgnored(java.util.LinkedHashMap qual_data, java.lang.String metric){
        return qual_data && (!qual_data.containsKey(metric) || !qual_data[metric].status || qual_data[metric].qc_status == QCStatus.WARNING)
    }

    static def select_qc_func(java.util.LinkedHashMap qual_data, java.lang.String metric, java.util.ArrayList qc_message, java.util.ArrayList ignored_message, java.util.LinkedHashMap meta_info, java.lang.String func) {
        def check_failed = 0
        def reisolate = 0
        def resequence = 0
        def check_ignored = 0
        def failed_p = false
        def checks = 0
        def function = func as FuncType

        switch (function) {
            case FuncType.GENERIC:
                (checks,
                reisolate,
                resequence,
                failed_p,
                check_failed,
                check_ignored) = ReportFunctions.generic_qc_func(qual_data, metric, ignored_message)
                break
            case FuncType.AUTOFAIL:
                (checks,
                reisolate,
                resequence,
                failed_p,
                check_failed,
                check_ignored) = ReportFunctions.autofail_reisolate(qual_data, metric, ignored_message)
                break
            case FuncType.READQUALITY:
                // meta_info.assembly is always false unless only an assembly is passed to
                // the pipeline. If meta_info.assembly is true the function will break and
                // simply return the default values and will not affect the final pass fail status
                // of the pipeline.
                if (!meta_info.assembly) {
                    (checks,
                    reisolate,
                    resequence,
                    failed_p,
                    check_failed,
                    check_ignored) = ReportFunctions.generic_qc_func(qual_data, metric, ignored_message)
                }
                break
            case FuncType.COVERAGE:
                // meta_info.assembly is always false unless only an assembly is passed to
                // the pipeline. If meta_info.assembly is true the function will break and
                // simply return the default values and will not affect the final pass fail status
                // of the pipeline.
                if (!meta_info.assembly) {
                    (checks,
                    reisolate,
                    resequence,
                    failed_p,
                    check_failed,
                    check_ignored) = ReportFunctions.generic_qc_func(qual_data, metric, ignored_message)
                    if (!failed_p && meta_info.downsampled) {
                        qc_message.add('The sample may have been downsampled too aggressively, if this is the cause please re-run sample with a different target depth.')
                    }
                }
                break
            case FuncType.CONTIG:
                (checks,
                reisolate,
                resequence,
                failed_p,
                check_failed,
                check_ignored) = ReportFunctions.contig_qc_func(qual_data, metric, ignored_message)
                break
            default:
                throw NoSuchMethodExeption("No function for $func exists.")
        }

        return [checks, reisolate, resequence, failed_p, check_failed, check_ignored]
    }

    static def contig_qc_func(java.util.LinkedHashMap qual_data, java.lang.String metric, java.util.ArrayList qc_message)    {
        def checks_failed = 0
        def reisolate = 0
        def resequence = 0
        def checks_ignored = 0
        def failed_p = false
        def checks = 0
        def metric_exists_and_failed =  metricFailed(qual_data, metric)
        def metric_ignored = metricIgnored(qual_data, metric)

        if (metric_exists_and_failed) {
            checks_failed = 1
            failed_p = true
        }else if (metric_ignored) {
          qc_message.add("$metric")
          checks_ignored = 1
        }else if (qual_data == null) {
          qc_message.add("$metric")
          checks_ignored = 1
        }
        checks += 1
        return [checks, reisolate, resequence, failed_p, checks_failed, checks_ignored]
    }

    static def generic_qc_func(java.util.LinkedHashMap qual_data, java.lang.String metric, java.util.ArrayList qc_message)     {
        def reisolate = 0
        def resequence = 0
        def failed_p = false
        def checks_failed = 0
        def checks_ignored = 0
        def checks = 0
        def metric_exists_and_failed =  metricFailed(qual_data, metric)
        def metric_ignored = metricIgnored(qual_data, metric)

        if (metric_exists_and_failed) {
            reisolate = 1
            resequence = 1
            failed_p = false
            checks_failed = 1
        }else if (metric_ignored) {
          qc_message.add("$metric")
          checks_ignored = 1
        }else if (qual_data == null) {
          qc_message.add("$metric")
          checks_ignored = 1
        }
        checks += 1
        return [checks, reisolate, resequence, failed_p, checks_failed, checks_ignored]
    }

    static def autofail_reisolate(java.util.LinkedHashMap qual_data, java.lang.String metric, java.util.ArrayList qc_message)     {
        def reisolate = 0
        def resequence = 0
        def failed_p = false
        def checks_failed = 0
        def checks_ignored = 0
        def checks = 0
        def metric_exists_and_failed =  metricFailed(qual_data, metric)
        def metric_ignored = metricIgnored(qual_data, metric)
        if (metric_exists_and_failed) {
            reisolate = 1
            resequence = 1
            failed_p = true
            checks_failed = 1
        }else if (metric_ignored) {
          qc_message.add("$metric")
          checks_ignored = 1
        }else if (qual_data == null) {
          qc_message.add("$metric")
          checks_ignored = 1
        }
        checks += 1
        return [checks, reisolate, resequence, failed_p, checks_failed, checks_ignored]
    }


    static def get_species(java.lang.String value, java.util.ArrayList search_phrases, int shortest_token, java.util.Map params){

      def qc_data = [params.QCReport.fallthrough.search, params.QCReport.fallthrough];
      if(value == null){
          return qc_data
      }
      // search_term_val used to be 0...
      def search_term_val = 0 // location of where the search key is in the search phrases array

      // matching here can likely be enhanced. wait for issue perhaps
      def comp_val_tokens = value.toLowerCase().split('_|\s').findAll{it.size() >= shortest_token};
      def comp_val = comp_val_tokens.join(" ")
      for(item in search_phrases){
          if(comp_val.contains(item[search_term_val].toLowerCase())){
              qc_data = item;
              break;
          }
      }
      return qc_data;
    }

    static def qc_params_species(java.util.Map qc_params){
      /*Retrieve all species QC data.*/
      def search_phrases = [];
      qc_params.each{k, v ->
          if(v.search in search_phrases){
              log.error "Duplicate search phrase ${v.search} included in your QCReport parameters. Bailing out as erroneous results could be included by accident. If you have fixed the issue re-run the pipeline with -resume to pick up where you left off."
              exit 1
          }
          search_phrases.add([v.search, v])
      }

      return search_phrases;
    }


  static def get_shortest_token(java.util.ArrayList search_params){

    def overly_large_number = Integer.MAX_VALUE;
    def shortest_entry = overly_large_number;
    for(i in search_params){
        def i_toks = i[0].split('_|\s')
        for(g in i_toks){
            def tok_size = g.size()
            if(tok_size < shortest_entry){
                shortest_entry = tok_size
            }
        }
    }
    return shortest_entry
  }

}
