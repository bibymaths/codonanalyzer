# Contributing to codonanalyzer

Thank you for your interest in contributing to **codonanalyzer**!  
This guide follows nf-core-style practices adapted for this project.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Branching Strategy](#branching-strategy)
4. [Making Changes](#making-changes)
5. [Running Tests](#running-tests)
6. [Running Linters](#running-linters)
7. [Pull Request Process](#pull-request-process)
8. [Commit Message Convention](#commit-message-convention)
9. [Documentation](#documentation)
10. [Reporting Bugs](#reporting-bugs)

---

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Getting Started

### Fork and Clone

```bash
# Fork via GitHub UI, then:
git clone https://github.com/<your-username>/codonanalyzer.git
cd codonanalyzer
git remote add upstream https://github.com/bibymaths/codonanalyzer.git
```

### Install Dependencies

```bash
# Python doc dependencies (requires uv or pip)
pip install -e ".[dev]"        # via pyproject.toml

# Perl quality tools
cpanm Perl::Critic Perl::Tidy

# Nextflow (requires Java 17+)
curl -s https://get.nextflow.io | bash
```

---

## Branching Strategy

| Branch type        | Naming convention                  | Example                          |
|--------------------|-------------------------------------|----------------------------------|
| Feature            | `feat/<short-description>`          | `feat/add-gc-content-plot`       |
| Bug fix            | `fix/<short-description>`           | `fix/longorf-frame-offset`       |
| Documentation      | `docs/<short-description>`          | `docs/update-api-reference`      |
| Refactor           | `refactor/<short-description>`      | `refactor/codon-hash-cleanup`    |
| CI / DevOps        | `ci/<short-description>`            | `ci/add-release-workflow`        |

Always branch from `main`:

```bash
git checkout main
git pull upstream main
git checkout -b feat/my-feature
```

---

## Making Changes

- **Perl scripts** (`scripts/*.pl`): do not change the logic unless fixing a bug. Follow GCP Perl5 style (see `.perlcriticrc`). Run `make tidy` before committing.
- **Nextflow files** (`main.nf`, `conf/*.config`): follow DSL2 conventions; keep processes atomic.
- **Python scripts** (`scripts/*.py`): format with `ruff format` and lint with `ruff check`.
- **Documentation** (`docs/`): edit Markdown directly; run `make docs` to verify MkDocs builds cleanly.

---

## Running Tests

```bash
# Unit tests (Perl Test::More via prove)
make test

# Or directly:
prove -v tests/unit/*.t

# Integration test (requires Nextflow and Docker/Singularity)
bash tests/run_tests.sh

# Nextflow test profile only
nextflow run main.nf -profile test,docker
```

---

## Running Linters

```bash
# All lint targets
make lint

# Perl critic only
perlcritic --profile .perlcriticrc scripts/*.pl

# Python ruff
ruff check scripts/
ruff format --check scripts/
```

---

## Pull Request Process

1. Ensure all tests pass locally (`make test`).
2. Ensure linters pass (`make lint`).
3. Ensure docs build without warnings (`make docs`).
4. Open a PR against `main` on GitHub.
5. Fill in the PR template (title, summary, testing done, checklist).
6. At least one review approval is required before merging.
7. Squash-merge preferred; rebase for clean history.

### PR Title Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) prefixes:

```
feat: add RSCU heatmap output
fix: correct ENc formula for 2-fold degenerate codons
docs: add hydropathy script API page
ci: pin nextflow version to 24.04.4
```

---

## Commit Message Convention

```
<type>(<scope>): <subject>

[optional body]

Co-authored-by: Your Name <email@example.com>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `ci`, `chore`.

---

## Documentation

- API pages live in `docs/api/`.
- Run `mkdocs serve` for a live preview.
- Run `mkdocs build --strict` to check for broken links.

---

## Reporting Bugs

Open a [GitHub Issue](https://github.com/bibymaths/codonanalyzer/issues) with:

- A minimal reproducible example (FASTA input if applicable)
- Nextflow version (`nextflow -version`)
- Operating system and container runtime
- Expected vs. actual output
