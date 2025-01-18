# Codon and GC Content Analysis Tools

This repository contains a suite of bioinformatics tools written in Perl, designed to analyze DNA sequences for codon usage, GC content, and hydropathy of amino acid sequences. These scripts were developed as part of a project focusing on the bioinformatics applications of DNA and protein analysis.

## Features

### 1. Codon Analyzer
Analyzes DNA sequences for the occurrence of rare codons based on E. coli codon usage. It identifies codons that are rarely used and calculates their percentage occurrence in the input sequence.

- **Input**: A DNA sequence file in plain text or FASTA format.
- **Output**: A list of rare codon percentages (`Codon_Percent_Values.txt`).
- **Usage**:
  ```bash
  perl CodonAnalyzer.pl INPUT.txt
  ```

### 2. GC Analyzer
Calculates the GC content of DNA sequences and performs a sliding window analysis to determine local GC content variations. This is useful for identifying regions of horizontal gene transfer and other genomic features.

- **Input**: A DNA sequence file in plain text or FASTA format.
- **Output**: Local GC content in a file (`LocalGC.txt`).
- **Usage**:
  ```bash
  perl GC_Analyzer.pl INPUT.txt
  ```

### 3. H-PLOT
Generates a hydropathy plot for amino acid sequences based on the Kyte-Doolittle scale. This tool maps the hydropathic character of protein sequences and outputs a file suitable for further analysis.

- **Input**: A FASTA file containing translated protein sequences.
- **Output**: Hydropathy values for each amino acid (`H_PLOT.txt`).
- **Usage**:
  ```bash
  perl H_Plot.pl Trans_Prot.txt
  ```

## Dependencies
These scripts require Perl. No additional dependencies are needed as they rely on standard Perl libraries.

## Installation
Clone the repository to your local system:
```bash
git clone https://github.com/your-repository-url.git
cd your-repository
```

## How to Run
1. Prepare your input file in the required format.
2. Run the corresponding script using Perl.
3. Check the output file for results.

The data used for testing these tools is from the **Escherichia coli O157:H7 str. Sakai** and **Escherichia coli CFT073** genomes. Below is a detailed description of the datasets:
 
## Test Data
- Protein sequences translated from the DNA of:
 1. *Escherichia coli O157:H7 str. Sakai* (Accession: [BA000007.2](https://www.ncbi.nlm.nih.gov/nuccore/BA000007.2/) | GI: 47118301).
 2. *Escherichia coli CFT073* (Accession: [AE014075.1](https://www.ncbi.nlm.nih.gov/nuccore/AE014075.1/) | GI: 26111730).
- Protein sequences were combined into a single FASTA file (`Trans_Prot.txt`).

## Example Outputs
- **Codon Analyzer**: A file showing the percentage of rare codons.
- **GC Analyzer**: A file with GC content across windows, indicating genomic variations.
- **H-PLOT**: A hydropathy map of the input protein sequences.

## Authors
- **Abhinav Mishra**  

## References
This project builds on various studies in bioinformatics and genomics. Key references include:
- Kyte, J., & Doolittle, R. F. (1982). *A simple method for displaying the hydropathic character of a protein*. J Mol Biol.
- Galtier, N., & Lobry, J. R. (1997). *Relationships between genomic G+C content, RNA secondary structures, and optimal growth temperature in prokaryotes*. J Mol Evol.

For the full list of references, see the `References` section in the report.
