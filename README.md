# codonanalyzer

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A524.04.0-brightgreen)](https://www.nextflow.io/)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.15384943.svg)](https://doi.org/10.5281/zenodo.15384943)

`codonanalyzer` is a Nextflow DSL2 pipeline for DNA multi-FASTA analysis with per-record fanout into Perl processing modules.

## Features

- Multi-FASTA splitting into per-record jobs
- Parallel codon, ORF, translation, hydropathy, and plotting stages
- Schema-validated parameters
- nf-core-style profile/config organization

## Quickstart

```bash
nextflow run main.nf -profile test
```

## Author

Abhinav Mishra  
mishraabhinav36@gmail.com

## License

BSD 3-Clause (see `LICENSE`).
