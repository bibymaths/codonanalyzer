# Parameters

!!! note
    Parameter validation and help are driven by `nextflow_schema.json` using the `nf-schema` plugin in `main.nf` and `nextflow.config`.

!!! tip
    Regenerate parameter documentation from schema whenever parameter definitions change.

--8<-- "parameters.generated.md"

## Parameter DAG context

```mermaid
flowchart LR
    A[input] --> B[SPLIT_FASTA]
    C[max_cpus/max_memory/max_time] --> D[Process resources]
    E[outdir] --> F[publishDir targets]
```
