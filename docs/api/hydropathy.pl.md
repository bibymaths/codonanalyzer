# hydropathy.pl

# Author: Abhinav Mishra

## Name

`hydropathy.pl` — calculate residue-level hydropathy and summary statistics.

## Synopsis

```bash
perl scripts/hydropathy.pl <in.fasta> <H_PLOT.txt> <H_SUMMARY.txt>
```

## Description

Computes Kyte–Doolittle hydropathy values for protein FASTA records and writes detailed and summary tabular outputs.

## Options

- `in.fasta`: translated protein FASTA input.
- `H_PLOT.txt`: per-residue hydropathy values output.
- `H_SUMMARY.txt`: sequence summary metrics output.

## Input/Output

- Input: single-record protein FASTA.
- Output: hydropathy detail (`*.hplot.txt`) and summary (`*.hsummary.txt`).

## Author

Abhinav Mishra (`mishraabhinav36@gmail.com`)

## Copyright and License

Copyright (c) 2025 Abhinav Mishra. BSD 3-Clause.
