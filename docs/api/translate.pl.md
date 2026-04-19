# translate.pl

# Author: Abhinav Mishra

## Name

`translate.pl` — translate DNA FASTA records into protein FASTA records.

## Synopsis

```bash
perl scripts/translate.pl <input.fasta> [output.fasta]
```

## Description

Applies standard codon translation from DNA sequence to amino-acid sequence, dropping non-ACGT characters and stop symbols.

## Options

- `input.fasta`: input FASTA with one sequence record.
- `output.fasta`: output translated FASTA.

## Input/Output

- Input: single-record DNA FASTA.
- Output: protein FASTA (`*.translated.fasta`).

## Author

Abhinav Mishra (`mishraabhinav36@gmail.com`)

## Copyright and License

Copyright (c) 2025 Abhinav Mishra. BSD 3-Clause.
