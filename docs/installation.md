# Installation

!!! note
    The pipeline entrypoint is `main.nf`, with runtime settings in `nextflow.config` and profile-specific overrides under `conf/`.

## Prerequisites

- Nextflow `>=24.04.0`
- Java 17+
- Perl 5
- Python 3 (for `scripts/plot_hydro.py`)

## Run profiles

=== "Local"

    ```bash
    nextflow run main.nf -profile standard --input data/input.fasta --outdir results
    ```

=== "Conda"

    ```bash
    nextflow run main.nf -profile conda --input data/input.fasta --outdir results
    ```

=== "SLURM"

    ```bash
    nextflow run main.nf -profile hpc --input data/input.fasta --outdir results
    ```

!!! danger
    Do not point `--outdir` to a directory with irreplaceable files, because pipeline publishing uses copy operations to materialize outputs.
