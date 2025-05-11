# Process Details

### 1. codon.pl
Generates codon usage statistics and GC content.
- **Input:** FASTA
- **Output:** `results/metric.txt`

### 2. longORF.pl
Detects the longest open reading frames.
- **Input:** FASTA
- **Output:** `results/orf`, `results/orf.fasta`

### 3. translate.pl
Translates the genomic sequence to protein.
- **Input:** FASTA
- **Output:** `results/translated.fasta`

### 4. hydropathy.pl
Calculates hydropathy values per amino acid.
- **Input:** translated FASTA
- **Output:** `hplot.txt`, `hsummary.txt`

### 5. plot_hydro.py
Generates a histogram plot of hydropathy values.
- **Input:** `hplot.txt`
- **Output:** `hplot.png`
