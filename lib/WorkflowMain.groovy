/*
 * WorkflowMain.groovy
 * nf-core-style pipeline initialisation and summary logging for codonanalyzer
 *
 * Author: Abhinav Mishra <mishraabhinav36@gmail.com>
 * License: MIT
 */

class WorkflowMain {

    /**
     * Initialise the pipeline: print banner, validate parameters, and log
     * the parameter summary.
     *
     * @param params    The Nextflow params object
     * @param workflow  The Nextflow workflow object
     * @param log       The Nextflow log object
     */
    static void initialise(params, workflow, log) {
        log.info Utils.pipelineBanner(workflow)

        // Print citation request
        log.info citationText(workflow)

        // Validate required parameters
        Utils.validateParams(params, log)

        // Print parameter summary
        log.info "Run parameters:\n" + Utils.paramsSummaryLog(params, workflow)
    }

    /**
     * Return a citation reminder string.
     *
     * @param workflow  The Nextflow workflow object
     * @return          Citation reminder string
     */
    static String citationText(workflow) {
        def name    = workflow.manifest.name ?: 'codonanalyzer'
        def version = workflow.manifest.version ?: 'dev'
        return """
---------------------------------------------------------
  If you use ${name} v${version} in your research, please cite:

  Mishra, A. (2025). codonanalyzer (v${version}).
  https://doi.org/10.5281/zenodo.15384943
---------------------------------------------------------
""".stripIndent()
    }

    /**
     * Print a completion summary to the log when the workflow finishes.
     *
     * @param params    The Nextflow params object
     * @param workflow  The Nextflow workflow object
     * @param log       The Nextflow log object
     */
    static void completionSummary(params, workflow, log) {
        if (workflow.success) {
            log.info "Pipeline completed successfully."
            log.info "Results written to: ${params.outdir}"
        } else {
            log.error "Pipeline completed with errors. Check logs in: ${workflow.launchDir}/.nextflow.log"
        }
    }
}
