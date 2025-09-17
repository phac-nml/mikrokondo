process MAX_SAMPLES_CHECK {
    tag "max_samples_check"
    label 'process_single'

    input:
    val sample_count  // number of samples provided to Mikrokondo

    output:
    path("max_samples_exceeded.error.txt"), optional: true, emit: failure_report

    script:
    if ((sample_count > params.max_samples) && !(params.max_samples == 0))
        """
        echo "Pipeline is being run with ${sample_count} items, which exceeds the limit of ${params.max_samples}. If running from command-line make sure that --max_samples 0, otherwise reduce number of samples selected." > max_samples_exceeded.error.txt
        """
    else
    """
    """
}