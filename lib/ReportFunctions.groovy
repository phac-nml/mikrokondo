
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
        return qual_data && qual_data.containsKey(metric) && !qual_data[metric].status
    }
    
    static def metricIgnored(java.util.LinkedHashMap qual_data, java.lang.String metric){
        return qual_data && (!qual_data.containsKey(metric) || !qual_data[metric].status || qual_data[metric].qc_status == QCStatus.WARNING)
    }

    static def select_qc_func(java.util.LinkedHashMap qual_data, java.lang.String metric, java.util.ArrayList qc_message, java.util.LinkedHashMap meta_info, java.lang.String func) {
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
                check_ignored) = ReportFunctions.generic_qc_func(qual_data, metric, qc_message)
                break
            case FuncType.AUTOFAIL:
                (checks,
                reisolate,
                resequence,
                failed_p,
                check_failed,
                check_ignored) = ReportFunctions.autofail_reisolate(qual_data, metric, qc_message)
                break
            case FuncType.READQUALITY:
                if (!meta_info.assembly) {
                    (checks,
                    reisolate,
                    resequence,
                    failed_p,
                    check_failed,
                    check_ignored) = ReportFunctions.generic_qc_func(qual_data, metric, qc_message)
                }
                break
            case FuncType.COVERAGE:
                if (!meta_info.assembly) {
                    (checks,
                    reisolate,
                    resequence,
                    failed_p,
                    check_failed,
                    check_ignored) = ReportFunctions.generic_qc_func(qual_data, metric, qc_message)
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
                check_ignored) = ReportFunctions.contig_qc_func(qual_data, metric, qc_message)
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
            checks_ignored = 1
        }else if (qual_data == null) {
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
            checks_ignored = 1
        }else if (qual_data == null) {
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
            checks_ignored = 1
        }else if (qual_data == null) {
            checks_ignored = 1
        }
        checks += 1
        return [checks, reisolate, resequence, failed_p, checks_failed, checks_ignored]
    }

}
