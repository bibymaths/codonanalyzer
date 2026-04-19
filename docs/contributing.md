# Contributing

!!! tip
    Keep process names stable in `main.nf` so documentation DAGs remain accurate.

## Development rules

1. Do not change biological logic in Perl scripts without dedicated review.
2. Keep `nextflow_schema.json` synchronized with `nextflow.config` params.
3. Validate docs and pipeline changes together.

## Local checks

```bash
nextflow run main.nf -profile test
mkdocs build
```
