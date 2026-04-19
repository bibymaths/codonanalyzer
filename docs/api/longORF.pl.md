# longORF.pl

Author: Abhinav Mishra

## Name

`longORF.pl` — identify the longest ORF(s) in FASTA input.

## Synopsis

```bash
perl scripts/longORF.pl <in.fasta> <out.table> [whole]
```

## Description

Scans forward and reverse-complement strands for ORFs using canonical start/stop codons, writes summary table and ORF FASTA.

## Options

- `in.fasta`: input FASTA with one sequence record.
- `out.table`: ORF summary table output.
- `whole` (optional): emit whole sequence to FASTA output.

## Input/Output

- Input: single-record DNA FASTA.
- Output: ORF table (`*.orf`) and FASTA (`*.orf.fasta`).

## Author

Abhinav Mishra (`mishraabhinav36@gmail.com`)

## Copyright and License

Copyright (c) 2025 Abhinav Mishra. BSD 3-Clause.
