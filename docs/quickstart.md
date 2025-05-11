# Quickstart

1. **Prepare your FASTA file**  
   Place your input file (e.g. `in.fasta`) in a `data` directory.

2. **Configure the pipeline**  
   Edit `config.yaml`:
   ```yaml
   fasta: path/to/in.fasta
   scripts_dir: scripts
 
3. **Run the pipeline**  
   Execute the Snakemake command to start the pipeline:
   ```bash
   snakemake --cores 1
   ``` 
   or 
   ```bash 
   snakemake --cores 1 --config fasta=alt.fasta scripts_dir=myscripts
   ``` 
   This will run the pipeline using 1 core and the specified FASTA file and scripts directory. 
