# About

**CodonAnalyzer** is a modular bioinformatics pipeline originally developed as a Perl project in 2015 by Abhinav Mishra and Namit Bhagwanani at JUIT, India, as part of their 6th-semester coursework in “Programming Languages for Bioinformatics”.

The current version (2025) modernizes and integrates the original Perl tools using the Snakemake workflow system. It adds standardized outputs, a configuration-driven design, Python-based plotting, and support for reproducible research environments.

### Historical Origins

- The initial pipeline included:
  - **CodonAnalyzer.pl** — for codon statistics and GC content
  - **GC_Analyzer.pl** — for GC content profiling across sequence windows
  - **H_Plot.pl** — for visualizing protein hydropathy using Kyte–Doolittle values
- These tools were tested on the complete genomes of *Escherichia coli* strains:
  - O157:H7 (Accession: BA000007.2)
  - CFT073 (Accession: AE014075.1)

### Current Features

- Reproducible, automated Snakemake workflow
- YAML-based configuration
- Output-ready visualizations with `matplotlib`
- Full transition from monolithic Perl scripts to composable bioinformatics processes

This evolution reflects the principles of modern scientific programming — reproducibility, modularity, and transparency — while honoring its academic roots.
