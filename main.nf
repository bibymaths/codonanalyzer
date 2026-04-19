nextflow.enable.dsl=2

include { validateParameters; paramsHelp } from 'plugin/nf-schema'

process SPLIT_FASTA {
    tag "split"
    publishDir "${params.outdir}/intermediate/split_fasta", mode: 'copy'

    input:
    path input_fasta

    output:
    path '*.fa', emit: records

    script:
    """
    awk '
      BEGIN { n=0 }
      /^>/ {
        n++
        h = substr($0,2)
        gsub(/[^A-Za-z0-9_.-]/, "_", h)
        out = sprintf("%04d_%s.fa", n, h)
      }
      { print >> out }
    ' "${input_fasta}"
    """
}

process CODON_ANALYSIS {
    tag { id }
    publishDir "${params.outdir}/intermediate/codon", mode: 'copy'

    input:
    tuple val(id), path(fasta)

    output:
    tuple val(id), path("${id}.metrics.txt"), emit: metrics

    script:
    """
    perl ${projectDir}/scripts/codon.pl ${fasta} ${id}.metrics.txt
    """
}

process LONG_ORF {
    tag { id }
    publishDir "${params.outdir}/intermediate/long_orf", mode: 'copy'

    input:
    tuple val(id), path(fasta)

    output:
    tuple val(id), path("${id}.orf"), emit: tables
    tuple val(id), path("${id}.orf.fasta"), emit: fastas

    script:
    """
    perl ${projectDir}/scripts/longORF.pl ${fasta} ${id}.orf
    """
}

process TRANSLATE_FASTA {
    tag { id }
    publishDir "${params.outdir}/intermediate/translate", mode: 'copy'

    input:
    tuple val(id), path(fasta)

    output:
    tuple val(id), path("${id}.translated.fasta"), emit: translated

    script:
    """
    perl ${projectDir}/scripts/translate.pl ${fasta} ${id}.translated.fasta
    """
}

process HYDROPATHY_PROFILE {
    tag { id }
    publishDir "${params.outdir}/intermediate/hydropathy", mode: 'copy'

    input:
    tuple val(id), path(translated_fasta)

    output:
    tuple val(id), path("${id}.hplot.txt"), emit: hplot
    tuple val(id), path("${id}.hsummary.txt"), emit: hsummary

    script:
    """
    perl ${projectDir}/scripts/hydropathy.pl ${translated_fasta} ${id}.hplot.txt ${id}.hsummary.txt
    """
}

process PLOT_HYDROPATHY {
    tag { id }
    publishDir "${params.outdir}/intermediate/plots", mode: 'copy'

    input:
    tuple val(id), path(hplot_txt)

    output:
    tuple val(id), path("${id}.hplot.png"), emit: png

    script:
    """
    python ${projectDir}/scripts/plot_hydro.py ${hplot_txt}
    mv hplot.png ${id}.hplot.png
    """
}

process GATHER_RESULTS {
    tag 'gather'
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path metrics_files
    path orf_tables
    path orf_fastas
    path translated_fastas
    path hplot_files
    path hsummary_files
    path plot_pngs

    output:
    path 'codonanalyzer_results/*', emit: all

    script:
    """
    mkdir -p codonanalyzer_results/per_record

    {
      for f in ${metrics_files}; do
        echo "### $f"
        cat "$f"
        echo
      done
    } > codonanalyzer_results/metrics.txt

    cat ${orf_tables} > codonanalyzer_results/orf
    cat ${orf_fastas} > codonanalyzer_results/orf.fasta
    cat ${translated_fastas} > codonanalyzer_results/translated.fasta

    first_hplot=$(echo ${hplot_files} | awk '{print $1}')
    head -n 1 "$first_hplot" > codonanalyzer_results/hplot.txt
    for f in ${hplot_files}; do
      tail -n +2 "$f" >> codonanalyzer_results/hplot.txt
    done

    first_hsummary=$(echo ${hsummary_files} | awk '{print $1}')
    head -n 1 "$first_hsummary" > codonanalyzer_results/hsummary.txt
    for f in ${hsummary_files}; do
      tail -n +2 "$f" >> codonanalyzer_results/hsummary.txt
    done

    cp ${plot_pngs} codonanalyzer_results/

    cp ${metrics_files} ${orf_tables} ${orf_fastas} ${translated_fastas} ${hplot_files} ${hsummary_files} ${plot_pngs} codonanalyzer_results/per_record/
    """
}

workflow {
    validateParameters()

    input_channel = Channel.fromPath(params.input, checkIfExists: true)

    split_records = SPLIT_FASTA(input_channel)
        .out
        .records
        .map { fasta -> tuple(fasta.baseName, fasta) }

    codon_results = CODON_ANALYSIS(split_records)
    orf_results = LONG_ORF(split_records)
    translated_results = TRANSLATE_FASTA(split_records)
    hydropathy_results = HYDROPATHY_PROFILE(translated_results.out.translated)
    plot_results = PLOT_HYDROPATHY(hydropathy_results.out.hplot)

    GATHER_RESULTS(
        codon_results.out.metrics.map { id, file -> file }.collect(),
        orf_results.out.tables.map { id, file -> file }.collect(),
        orf_results.out.fastas.map { id, file -> file }.collect(),
        translated_results.out.translated.map { id, file -> file }.collect(),
        hydropathy_results.out.hplot.map { id, file -> file }.collect(),
        hydropathy_results.out.hsummary.map { id, file -> file }.collect(),
        plot_results.out.png.map { id, file -> file }.collect()
    )

    if (params.help) {
        log.info paramsHelp()
    }
}
