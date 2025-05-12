# CodonAnalyzer
 
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.15384943.svg)](https://doi.org/10.5281/zenodo.15384943)
 
Originally developed using Perl in 2015, this pipeline has been modernized in 2025 with reproducibility and modularity in mind.

---

## Features

- Codon usage statistics and GC content
- Longest ORF extraction
- Protein sequence translation
- Hydropathy calculation (Kyte–Doolittle)
- Plotting via Python + Matplotlib
- Configurable via `config.yaml`
- Reproducible workflow using Snakemake

---

## Quickstart

```bash
git clone https://github.com/yourusername/codonanalyzer.git
cd codonanalyzer
``` 
### Setup Environment 

```bash 
conda install -c conda-forge -c bioconda snakemake matplotlib numpy=2.0
```  

or using environment.yml: 

```bash 
conda env create -f environment.yml 
``` 

Then, run:

```bash
snakemake --cores 1
```

---

## Documentation

See the full documentation [here](https://bibymaths.github.io/codonanalyzer).

---

## Authors

* Abhinav Mishra (2025)
* Namit Bhagwanani (original 2015 version)

For full historical context, see [About](docs/about.md).

---

## License

BSD 3-Clause. See [LICENSE](LICENSE).
