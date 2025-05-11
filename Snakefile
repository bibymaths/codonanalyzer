

configfile: "config.yaml"

# Use values from config
FASTA       = config["fasta"]
SCRIPTS_DIR = config.get("scripts_dir", ".")

rule all:
    input:
        "results/metrics.txt",
        "results/orf",
        "results/orf.fasta",
        "results/translated.fasta",
        "results/hplot.txt",
        "results/hsummary.txt",
        "results/hplot.png"

rule codon:
    input:
        fasta=FASTA
    output:
        "results/metrics.txt"
    shell:
        """
        mkdir -p results
        perl {SCRIPTS_DIR}/codon.pl {input.fasta} {output}
        """

rule longorf:
    input:
        fasta=FASTA
    output:
        summary="results/orf",
        fasta="results/orf.fasta"
    shell:
        """
        mkdir -p results
        perl {SCRIPTS_DIR}/longORF.pl {input.fasta} results/orf
        """

rule translate:
    input:
        fasta=FASTA
    output:
        "results/translated.fasta"
    shell:
        """
        mkdir -p results
        perl {SCRIPTS_DIR}/translate.pl {input.fasta} {output}
        """

rule hydropathy:
    input:
        prot="results/translated.fasta"
    output:
        hplot="results/hplot.txt",
        hsummary="results/hsummary.txt"
    shell:
        """
        mkdir -p results
        perl {SCRIPTS_DIR}/hydropathy.pl {input.prot} {output.hplot} {output.hsummary}
        """

rule plot:
    input:
        "results/hplot.txt"
    output:
        "results/hplot.png"
    shell:
        """
        mkdir -p results
        cd results
        python ../{SCRIPTS_DIR}/plot_hydro.py hplot.txt
        """
