# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in **codonanalyzer**, please do **not** open a public GitHub issue.  
Instead, report it privately via one of the following methods:

1. **GitHub Private Vulnerability Reporting** (preferred):  
   Navigate to the [Security tab](https://github.com/bibymaths/codonanalyzer/security/advisories) of this repository and click **"Report a vulnerability"**.

2. **Email**:  
   Send a detailed report to **mishraabhinav36@gmail.com** with the subject line:  
   `[SECURITY] codonanalyzer vulnerability report`

### What to Include

- A clear description of the vulnerability and its potential impact
- Steps to reproduce (including any input files, command-line arguments, or environment details)
- The version of codonanalyzer affected
- Any suggested remediation, if known

### What to Expect

- Acknowledgement of your report within **5 business days**
- An initial assessment within **14 days**
- A fix or mitigation plan communicated back to you before any public disclosure
- Credit in the release notes (unless you prefer to remain anonymous)

## Scope

This policy covers:

- The Nextflow pipeline (`main.nf`, `conf/`)
- Perl analysis scripts (`scripts/*.pl`)
- Python visualisation scripts (`scripts/*.py`)
- Docker images published under `ghcr.io/bibymaths/codonanalyzer`

Out of scope:

- Vulnerabilities in third-party dependencies (Nextflow, Perl, Python, BioPerl, matplotlib) — please report these upstream
- Issues in the documentation site only

## Disclosure Policy

We follow a **coordinated disclosure** model. We ask that you allow us reasonable time to address the issue before any public disclosure.
