# Output

Final merged outputs are written to:

- `${params.outdir}/codonanalyzer_results/metrics.txt`
- `${params.outdir}/codonanalyzer_results/orf`
- `${params.outdir}/codonanalyzer_results/orf.fasta`
- `${params.outdir}/codonanalyzer_results/translated.fasta`
- `${params.outdir}/codonanalyzer_results/hplot.txt`
- `${params.outdir}/codonanalyzer_results/hsummary.txt`
- `${params.outdir}/codonanalyzer_results/*.hplot.png`
- `${params.outdir}/codonanalyzer_results/per_record/*`

!!! warning
    Combined files are concatenated from per-record outputs; if downstream tools require sorting, sort post-pipeline using a stable record identifier.

```mermaid
flowchart LR
    A[Per-record outputs] --> B[GATHER_RESULTS]
    B --> C[Combined outputs]
```
