# codon.pl

# Author: Abhinav Mishra

## Name

`codon.pl` — compute codon usage and nucleotide composition metrics for one FASTA record.

## Synopsis

```bash
perl scripts/codon.pl <in.fasta> <out.txt>
```

## Description

Calculates nucleotide counts, GC/AT percentages and skews, dinucleotide/codon counts, RSCU, ENc, amino-acid composition, ORF statistics, sliding-window GC, and 3-mer entropy.

## Options

- `in.fasta`: input FASTA with one sequence record.
- `out.txt`: metrics output text file.

## Input/Output

- Input: single-record DNA FASTA.
- Output: plain-text metrics report (`*.metrics.txt`).

## Author

Abhinav Mishra (`mishraabhinav36@gmail.com`)

## Copyright and License

Copyright (c) 2025 Abhinav Mishra. BSD 3-Clause.
