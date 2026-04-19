You are a senior bioinformatics software engineer and DevOps specialist. Finalize and polish this codebase into a production-grade, nf-core-style pipeline. The codebase processes DNA multi-FASTA files using Perl5 scripts. Follow every instruction below with precision.

---
## CONTEXT
- Root contains: Perl5 scripts in scripts/, data/ directory with .fasta files, existing docs/, existing Snakemake workflow and config files, environment.yml
- Each .pl script in scripts/ processes a single FASTA file (one header per call)
- Target deployment: server with 96 CPU cores, 1 TB RAM
- Author for all files: Abhinav Mishra, mishraabhinav36@gmail.com
- Pipeline name: codonanalyzer
- GitHub org/username: [GITHUB_HANDLE]
- Docker Hub / GHCR username: ghcr.io
- Year: 2025

---
## 1. NEXTFLOW MIGRATION (DO NOT MODIFY .pl SCRIPTS)
- Convert the existing Snakemake workflow into a Nextflow DSL2 pipeline (main.nf) that:
  - Accepts a multi-FASTA input file (up to 1000 headers) as a parameter: params.input
  - Splits the multi-FASTA into per-record temporary FASTA files using a Nextflow process (splitFasta or a custom Channel.fromPath + splitFasta operator)
  - Fans out each single-record FASTA file as an independent item in a Nextflow channel
  - Passes each single-record FASTA to the appropriate .pl script via a dedicated Nextflow process, wrapping the script call exactly as-is, e.g.: script: "perl ${projectDir}/scripts/process.pl ${fasta}"
  - Collects and merges results in a final gather process
  - Uses publishDir for outputs, with mode: 'copy'
  - Is parallelized across all available cores using process.cpus and executor config
- Create nextflow.config with:
  - params block (input, outdir, max_cpus = 96, max_memory = '1000.GB', max_time = '240.h')
  - profiles: standard (local), hpc (SLURM), docker, singularity, conda, test
  - process defaults with errorStrategy = 'retry', maxRetries = 2
  - manifest block: name, author, description, version, nextflowVersion, doi
  - timeline, report, trace, dag enabled in the output dir
- Create conf/base.config, conf/resources.config, conf/test.config following nf-core conventions
- Create assets/multiqc_config.yml
- DELETE: Snakemake workflow file (Snakefile), all snakemake config files (config.yaml, config.yml, etc.)
- Keep ONLY in root: main.nf, nextflow.config, conf/, assets/

---
## 2. DOCUMENTATION (MkDocs + Material Theme)
- Retain and upgrade existing docs/ to MkDocs with Material theme
- mkdocs.yml must include:
  - theme: material with palette (primary: teal, accent: cyan), toggle for dark/light mode
  - Plugins: search, mkdocstrings (for any future Python), autorefs, glightbox, minify, git-revision-date-localized, awesome-pages, include-markdown
  - Markdown extensions: admonition, pymdownx.superfences (with mermaid support), pymdownx.tabbed, pymdownx.details, pymdownx.highlight, attr_list, md_in_html, toc (permalink: true)
  - nav structure: Home, Installation, Usage, Pipeline Overview, Processes, Parameters, Output, API Reference (Perl), Contributing, Changelog, Code of Conduct
- For every pipeline stage documented:
  - Embed a Mermaid flowchart showing the Nextflow DAG for that stage, sourced from the actual process names in main.nf
  - Use the nextflow-io/nf-schema or nf-validation plugin to auto-generate parameter docs
- Use admonition boxes extensively:
  - !!! tip for best practices
  - !!! note for informational context
  - !!! warning for resource-heavy steps or data caveats
  - !!! danger for destructive operations
- Create docs/overrides/main.html for custom JS/CSS hooks
- Create docs/stylesheets/extra.css and docs/javascripts/extra.js
  - extra.css: custom pipeline color scheme, code block styling, badge styles
  - extra.js: copy-button enhancement, any Mermaid theme overrides
- All docs must be grounded in actual implementation: reference specific .pl script names, actual Nextflow process names, real parameter names from nextflow.config

---
## 3. API REFERENCE FOR PERL SCRIPTS (in MkDocs)
- Since there are no Python scripts, use Perl POD (Plain Old Documentation) for API reference
- For EACH .pl script in scripts/:
  - Add/update full POD documentation inside the file: =head1 NAME, =head1 SYNOPSIS, =head1 DESCRIPTION, =head1 OPTIONS, =head1 INPUT/OUTPUT, =head1 AUTHOR, =head1 COPYRIGHT AND LICENSE
  - Generate a corresponding docs/api/<script_name>.md file using pod2markdown (via a pre-build hook or manual conversion), so MkDocs can render it
- In mkdocs.yml, add an "API Reference" nav section with one page per .pl script
- Add a docs/api/index.md that lists all scripts with one-line descriptions
- In the MkDocs Material theme, render these pages with code highlighting for Perl

---
## 4. AUTHOR AND COPYRIGHT IN .pl SCRIPTS
- Add to the top of EVERY .pl file in scripts/:
  - A shebang: #!/usr/bin/env perl
  - use strict; use warnings; use utf8;
  - A header comment block:
    # ============================================================
    # Script: <filename>
    # Author: Abhinav Mishra <mishraabhinav36@gmail.com>
    # Date:   2025
    # Copyright (c) 2025 Abhinav Mishra. All rights reserved.
    # License: MIT (see LICENSE file in repository root)
    # GCP: Perl5 (GNU Coding Practices for Perl5)
    # ============================================================
  - Do NOT change any logic, subroutines, or I/O behavior

---
## 5. PYTHON ENVIRONMENT → uv + pyproject.toml
- DELETE environment.yml entirely
- If Python is used anywhere (helper scripts, docs build, pre-commit hooks):
  - Create pyproject.toml using PEP 517/518 with uv-compatible format:
    [build-system] requires = ["hatchling"], build-backend = "hatchling.build"
    [project] with name, version, dependencies (mkdocs-material, mkdocstrings, etc.)
    [tool.uv] section if needed
    [tool.ruff] for linting (see section 6)
  - Add .python-version file pinning Python 3.11+
- If Python is NOT used at all, still create a minimal pyproject.toml for docs dependencies only (mkdocs + plugins), with uv as the package manager
- Add a uv.lock file comment: "Run uv sync to install"

---
## 6. LINTING AND TESTING
### Perl Linting
- Add Perl::Critic configuration file .perlcriticrc at root:
  severity = 3
  theme = core
  Include all relevant policies for bioinformatics Perl5 code
- Add Perl::Tidy configuration file .perltidyrc at root (standard nf-core-like style)
- Add a lint target in a Makefile or justfile: perlcritic scripts/*.pl && perltidy --check-only scripts/*.pl
- In the Nextflow CI workflow, run perlcritic as a pre-flight check before pipeline execution

### Perl Tests
- Create tests/ directory with:
  - tests/unit/ — one .t test file per .pl script using Test::More and Test::Exception
    - Test: script loads without errors (use_ok or require_ok)
    - Test: script handles missing input file gracefully
    - Test: script produces expected output format for a minimal mock FASTA in tests/fixtures/
  - tests/fixtures/ — minimal mock .fasta files for testing
  - tests/integration/ — one integration test that runs the full Nextflow pipeline on tests/fixtures/ test data using profile: test
  - tests/run_tests.sh — shell script that: runs prove -v tests/unit/*.t, then runs nextflow run main.nf -profile test
- Add a prove and nextflow test step in CI

### Python/Docs Linting (if pyproject.toml exists)
- Add ruff configuration in pyproject.toml:
  [tool.ruff] line-length = 88, target-version = "py311"
  [tool.ruff.lint] select = ["E", "F", "I", "N", "UP", "B"]

---
## 7. COMMUNITY AND LEGAL FILES (root level)
Create the following files with appropriate, non-placeholder content:

- NOTICE: Apache-style notice listing author, year, project name, and any third-party attributions
- TERMS_OF_USE.md: Plain-language terms of use for academic and commercial use, referencing the LICENSE
- CODEOWNERS: Map all .pl scripts to author, all .nf files to author, docs/ to author. Format: * @[GITHUB_HANDLE]
- CODE_OF_CONDUCT.md: Contributor Covenant v2.1 adapted for bioinformatics community
- CHANGELOG.md: Keep-a-Changelog format, start with [Unreleased] then [0.1.0] initial release entry documenting: Nextflow migration, docs, Docker, tests, linting setup
- SECURITY.md: Vulnerability reporting instructions
- CONTRIBUTING.md: nf-core-style contribution guide: fork, branch naming, PR template, how to run tests, how to run linting

---
## 8. GITHUB ACTIONS: docs.yml UPDATE
Update .github/workflows/docs.yml to:
- Trigger on: push to main and docs/** paths, pull_request
- Jobs:
  1. lint-perl: runs perlcritic on all scripts/*.pl
  2. test-perl: runs prove -v tests/unit/*.t
  3. test-nextflow: runs nextflow run main.nf -profile test,docker
  4. build-docs: uv sync, mkdocs build --strict
  5. deploy-docs: mkdocs gh-deploy (only on push to main)
- Use ubuntu-latest, cache uv and Perl cpan deps
- Add Nextflow installation step using nf-core/setup-nextflow action

---
## 9. DOCKER
Create the following files:

### Dockerfile
- Multi-stage build
- Stage 1 (builder): Ubuntu 22.04, install Perl5, cpanm, all required CPAN modules (Parse::RecDescent, BioPerl, etc. — infer from .pl use statements), install Nextflow, install Java 17 (Nextflow dependency)
- Stage 2 (runtime): minimal Ubuntu 22.04, copy Perl env from builder, copy scripts/, copy main.nf and conf/
- LABEL: org.opencontainers.image.* metadata (source, version, authors, description)
- USER: non-root user (pipeline)
- WORKDIR /pipeline
- ENTRYPOINT ["nextflow", "run", "main.nf"]
- CMD ["--help"]

### .dockerignore
- Exclude: .git, data/, results/, work/, .nextflow/, tests/fixtures/*.fasta (large), docs/, *.log, __pycache__

### docker-compose.yml (production)
- Service: pipeline, build: ., volumes: ./data:/pipeline/data, ./results:/pipeline/results, environment: NXF_OPTS, NXF_WORK

### docker-compose.dev.yml (development, extends docker-compose.yml)
- Mounts entire project root for live editing, overrides ENTRYPOINT to /bin/bash

### docker_up.sh
- docker compose up -d with --build flag, prints logs

### docker_down.sh
- docker compose down -v

### docker_interactive.sh
- docker compose -f docker-compose.dev.yml run --rm pipeline /bin/bash

### docker_push.sh
- Tags image as ghcr.io/codonanalyzer:latest and :[GIT_TAG], pushes both

### docker_test_local.sh
- Builds image, runs nextflow run main.nf -profile test,docker inside container, checks exit code

---
## 10. GITHUB ACTIONS: release.yml
Create .github/workflows/release.yml:
- Trigger: push tags matching v*.*.*
- Jobs:
  1. docker-build-push:
     - Checkout, set up QEMU + Docker Buildx
     - Login to GHCR (ghcr.io) using GITHUB_TOKEN
     - Extract metadata (tags: semver, latest)
     - Build and push multi-arch image (linux/amd64, linux/arm64)
  2. github-release:
     - Create GitHub Release using softprops/action-gh-release
     - Auto-generate release notes from CHANGELOG.md section for the tag
     - Upload any pipeline assets (schema_input.json, assets/multiqc_config.yml) as release artifacts
  3. nextflow-test-on-release:
     - Run nextflow run main.nf -profile test,docker as a final smoke test before marking release complete
- Use environment: production for the push job, requiring a reviewer approval

---
## 11. CITATION AND ZENODO
### .zenodo.json
- creators: [{"name": "Abhinav Mishra", "affiliation": "Independent Researcher", "orcid": "[YOUR ORCID]"}]
- title, description, version, license: mit, keywords: ["bioinformatics", "nextflow", "fasta", "nf-core", "perl"]
- communities, related_identifiers (link to GitHub repo)

### CITATION.cff
- cff-version: 1.2.0
- Full CFF format with message, authors, title, version, doi (placeholder), repository-code, license, keywords
- preferred-citation block for journal paper if applicable

---
## 12. nf-core COMPATIBILITY
- Add nextflow_schema.json (nf-core/nf-validation compatible): define all params with type, description, help_text, fa_icon, default, enum where applicable
- Add assets/schema_input.json for samplesheet validation if using a samplesheet input
- Add lib/Utils.groovy and lib/WorkflowMain.groovy following nf-core template patterns for:
  - Parameter validation on startup
  - Summary log printing (NXF log.info)
  - Citation display
- Add .nf-core.yml declaring the template version and lint-ignore rules
- Ensure all process labels (process_low, process_medium, process_high) are defined in conf/base.config following nf-core label conventions
- Add CITATIONS.md listing all tools with DOIs

---
## OUTPUT STRUCTURE EXPECTED AFTER ALL CHANGES
```
.
├── main.nf
├── nextflow.config
├── nextflow_schema.json
├── pyproject.toml
├── .python-version
├── Makefile (or justfile)
├── .perlcriticrc
├── .perltidyrc
├── .nf-core.yml
├── .dockerignore
├── Dockerfile
├── docker-compose.yml
├── docker-compose.dev.yml
├── docker_up.sh
├── docker_down.sh
├── docker_interactive.sh
├── docker_push.sh
├── docker_test_local.sh
├── CITATION.cff
├── .zenodo.json
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CODEOWNERS
├── CONTRIBUTING.md
├── NOTICE
├── SECURITY.md
├── TERMS_OF_USE.md
├── LICENSE
├── conf/
│   ├── base.config
│   ├── resources.config
│   └── test.config
├── lib/
│   ├── Utils.groovy
│   └── WorkflowMain.groovy
├── assets/
│   └── multiqc_config.yml
├── scripts/
│   └── *.pl  (UNCHANGED logic, updated headers + POD)
├── tests/
│   ├── unit/*.t
│   ├── integration/
│   ├── fixtures/*.fasta
│   └── run_tests.sh
├── docs/
│   ├── index.md
│   ├── api/
│   │   ├── index.md
│   │   └── <script_name>.md (one per .pl)
│   ├── stylesheets/extra.css
│   ├── javascripts/extra.js
│   └── overrides/main.html
├── mkdocs.yml
└── .github/
    └── workflows/
        ├── docs.yml  (updated)
        └── release.yml (new)
```

Execute all changes in order. Do not hallucinate file content — infer everything from the actual existing .pl scripts, process names, and file structure. Where information is ambiguous, leave a clearly marked TODO: [YOUR_ACTION_REQUIRED] placeholder.
