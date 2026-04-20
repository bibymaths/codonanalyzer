# Processes

## SPLIT_FASTA

!!! note
    Input: `params.input` multi-FASTA.

```mermaid
flowchart LR
    A[params.input] --> B[SPLIT_FASTA]
    B --> C[*.fa per record]
```

## CODON_ANALYSIS (`scripts/codon.pl`)

!!! warning
    This process computes many metrics, including codon-level and entropy statistics.

```mermaid
flowchart LR
    A[record.fa] --> B[CODON_ANALYSIS]
    B --> C[id.metrics.txt]
```

## LONG_ORF (`scripts/longORF.pl`)

```mermaid
flowchart LR
    A[record.fa] --> B[LONG_ORF]
    B --> C[id.orf]
    B --> D[id.orf.fasta]
```

## TRANSLATE_FASTA (`scripts/translate.pl`)

```mermaid
flowchart LR
    A[record.fa] --> B[TRANSLATE_FASTA]
    B --> C[id.translated.fasta]
```

## HYDROPATHY_PROFILE (`scripts/hydropathy.pl`)

```mermaid
flowchart LR
    A[id.translated.fasta] --> B[HYDROPATHY_PROFILE]
    B --> C[id.hplot.txt]
    B --> D[id.hsummary.txt]
```

## PLOT_HYDROPATHY (`scripts/plot_hydro.py`)

```mermaid
flowchart LR
    A[id.hplot.txt] --> B[PLOT_HYDROPATHY]
    B --> C[id.hplot.png]
```

## HEATMAP_PLOT (`scripts/heatmap.sh`)

Generates a 2-D genome hydropathy heatmap by binning the per-position hydropathy values from `HYDROPATHY_PROFILE` into a symmetric matrix and rendering it with gnuplot.

Input: `id.hplot.txt` produced by `HYDROPATHY_PROFILE`.
Output: one PNG file named `<prefix>_<id>.png` (a diverging Blue–White–Red heatmap of average hydropathy across genomic windows).

```mermaid
flowchart LR
    A[id.hplot.txt] --> B[HEATMAP_PLOT]
    B --> C[id_seqname.png]
```

## CODON_PLOTS (`scripts/codon_plots.py`)

Produces a multi-panel figure visualising codon usage metrics from `CODON_ANALYSIS`: nucleotide composition pie chart, scalar sequence metrics, ORF statistics, codon-count heatmap, RSCU heatmap, amino-acid composition bar chart, and sliding-window GC%.

Input: `id.metrics.txt` produced by `CODON_ANALYSIS`.
Output: `id.codon_plots.png` and `id.codon_plots.pdf`.

```mermaid
flowchart LR
    A[id.metrics.txt] --> B[CODON_PLOTS]
    B --> C[id.codon_plots.png]
    B --> D[id.codon_plots.pdf]
```

## GATHER_RESULTS

!!! danger
    This is the terminal merge stage and rewrites combined outputs under `${params.outdir}/codonanalyzer_results/`.

```mermaid
flowchart LR
    A[metrics/orf/translated/hplot/hsummary/png] --> B[GATHER_RESULTS]
    B --> C[metrics.txt]
    B --> D[orf + orf.fasta]
    B --> E[translated.fasta]
    B --> F[hplot.txt + hsummary.txt]
    B --> G[hplot PNGs]
```
