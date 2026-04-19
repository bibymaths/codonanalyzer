/*
 * Utils.groovy
 * nf-core-style utility functions for codonanalyzer
 *
 * Author: Abhinav Mishra <mishraabhinav36@gmail.com>
 * License: MIT
 */

class Utils {

    /**
     * Validate required pipeline parameters and exit with an informative
     * error message if any are missing or invalid.
     *
     * @param params   The Nextflow params object
     * @param log      The Nextflow log object
     */
    static void validateParams(params, log) {
        if (!params.input) {
            log.error "Parameter '--input' is required. Please provide a path to a FASTA file."
            System.exit(1)
        }

        def inputFile = new File(params.input as String)
        if (!inputFile.exists()) {
            log.error "Input file not found: ${params.input}"
            System.exit(1)
        }

        if (params.window_size && (params.window_size as int) < 1) {
            log.error "Parameter '--window_size' must be a positive integer."
            System.exit(1)
        }
    }

    /**
     * Return a formatted summary string of the current parameter set.
     *
     * @param params    The Nextflow params object
     * @param workflow  The Nextflow workflow object
     * @return          A multi-line summary string
     */
    static String paramsSummaryLog(params, workflow) {
        def summary = [:]
        summary['Pipeline']        = workflow.manifest.name ?: 'codonanalyzer'
        summary['Version']         = workflow.manifest.version ?: 'dev'
        summary['Nextflow version'] = workflow.nextflow.version
        summary['Run name']        = workflow.runName
        summary['Input']           = params.input
        summary['Output dir']      = params.outdir
        summary['Window size']     = params.window_size ?: 19
        summary['Profile']         = workflow.profile

        def maxLen = summary.keySet().collect { it.length() }.max()
        def lines = summary.collect { k, v ->
            "  ${k.padRight(maxLen)} : ${v}"
        }
        return lines.join('\n')
    }

    /**
     * Produce a banner-style header string for the pipeline log.
     *
     * @param workflow  The Nextflow workflow object
     * @return          Banner string
     */
    static String pipelineBanner(workflow) {
        return """
==========================================================
  c o d o n a n a l y z e r
==========================================================
  Pipeline : ${workflow.manifest.name ?: 'codonanalyzer'}
  Version  : ${workflow.manifest.version ?: 'dev'}
  Homepage : ${workflow.manifest.homePage ?: 'https://github.com/bibymaths/codonanalyzer'}
==========================================================
""".stripIndent()
    }
}
