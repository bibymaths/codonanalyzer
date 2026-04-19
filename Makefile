# Makefile for codonanalyzer
# Targets: lint, tidy, test, docs, all

PERL_SCRIPTS := scripts/codon.pl scripts/longORF.pl scripts/translate.pl scripts/hydropathy.pl
UNIT_TESTS   := tests/unit/*.t

.PHONY: all lint tidy test docs

all: lint test docs

lint:
@echo "==> Running perlcritic..."
perlcritic --profile .perlcriticrc $(PERL_SCRIPTS)
@echo "==> Running ruff check..."
ruff check scripts/

tidy:
@echo "==> Running perltidy..."
perltidy $(PERL_SCRIPTS)
@echo "==> Running ruff format..."
ruff format scripts/

test:
@echo "==> Running unit tests..."
prove -v $(UNIT_TESTS)

docs:
@echo "==> Building MkDocs..."
mkdocs build --strict
