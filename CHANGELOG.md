# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Multi-architecture Docker image (`linux/amd64`, `linux/arm64`) via GitHub Actions release workflow
- `CODEOWNERS` file mapping all sources to `@bibymaths`
- `SECURITY.md` with vulnerability reporting instructions
- `TERMS_OF_USE.md` with plain-language academic and commercial terms
- `CITATIONS.md` listing all third-party tools with DOIs/URLs
- `CITATION.cff` for software citation (CFF v1.2.0)
- `.zenodo.json` for Zenodo deposit metadata
- `pyproject.toml` (PEP 517/518, hatchling) with doc-build dependencies and ruff lint config
- `.python-version` pinning Python 3.11
- `.perlcriticrc` and `.perltidyrc` for Perl code quality
- `Makefile` with `lint`, `tidy`, `test`, `docs`, `all` targets
- `.nf-core.yml` template version and lint-ignore rules
- `.dockerignore` for lean Docker builds
- `Dockerfile` multi-stage build (builder + runtime)
- `docker-compose.yml`, `docker-compose.dev.yml`
- Docker helper shell scripts: `docker_up.sh`, `docker_down.sh`, `docker_interactive.sh`, `docker_push.sh`, `docker_test_local.sh`
- `lib/Utils.groovy` and `lib/WorkflowMain.groovy` nf-core-style Groovy utilities
- `tests/` directory with fixtures, unit `.t` files, integration test, and `run_tests.sh`
- `docs/api/index.md` listing all four Perl scripts
- `.github/workflows/docs.yml` with lint-perl, test-perl, build-docs, and deploy-docs jobs
- `.github/workflows/release.yml` for Docker multi-arch push and GitHub Release

### Changed
- Header comment blocks added to all four Perl scripts (`codon.pl`, `longORF.pl`, `translate.pl`, `hydropathy.pl`) with author, year, and license metadata
- `use utf8;` added to all four Perl scripts

### Removed
- `environment.yml` (replaced by `pyproject.toml` for Python dependencies)

## [0.1.0] - 2025-01-01

### Added
- Nextflow DSL2 pipeline (`main.nf`) with processes: `SPLIT_FASTA`, `CODON_ANALYSIS`, `LONG_ORF`, `TRANSLATE_FASTA`, `HYDROPATHY_PROFILE`, `PLOT_HYDROPATHY`, `GATHER_RESULTS`
- `nextflow.config` with parameter defaults and profiles: `standard`, `hpc`, `docker`, `singularity`, `conda`, `test`
- `nextflow_schema.json` for nf-core-compatible parameter schema
- Configuration files: `conf/base.config`, `conf/resources.config`, `conf/test.config`
- Perl analysis scripts: `scripts/codon.pl`, `scripts/longORF.pl`, `scripts/translate.pl`, `scripts/hydropathy.pl`
- Python visualisation script: `scripts/plot_hydro.py`
- MkDocs documentation site (`mkdocs.yml`, `docs/`) with Material theme
- `assets/multiqc_config.yml` for MultiQC report configuration
- Initial `README.md` and `LICENSE` (MIT)
- GitHub Actions workflow for deploying MkDocs to GitHub Pages

[Unreleased]: https://github.com/bibymaths/codonanalyzer/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bibymaths/codonanalyzer/releases/tag/v0.1.0
