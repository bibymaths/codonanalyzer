# ============================================================
# Dockerfile for codonanalyzer
# Multi-stage build: builder + runtime
# ============================================================

# ---- Stage 1: builder ----
FROM ubuntu:22.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG NEXTFLOW_VERSION=24.04.4

RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-17-jre-headless \
        perl \
        curl \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Install Nextflow
RUN curl -fsSL https://get.nextflow.io | bash \
    && mv nextflow /usr/local/bin/nextflow \
    && chmod +x /usr/local/bin/nextflow

# ---- Stage 2: runtime ----
FROM ubuntu:22.04 AS runtime

ARG DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="codonanalyzer" \
      org.opencontainers.image.description="Nextflow DSL2 pipeline for codon usage analysis" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.authors="Abhinav Mishra <mishraabhinav36@gmail.com>" \
      org.opencontainers.image.source="https://github.com/bibymaths/codonanalyzer" \
      org.opencontainers.image.licenses="MIT"

RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-17-jre-headless \
        perl \
        python3 \
        python3-matplotlib \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Nextflow binary from builder
COPY --from=builder /usr/local/bin/nextflow /usr/local/bin/nextflow

# Create non-root user
RUN useradd -ms /bin/bash pipeline

WORKDIR /pipeline

# Copy pipeline files
COPY scripts/ ./scripts/
COPY main.nf  ./main.nf
COPY conf/    ./conf/

RUN chown -R pipeline:pipeline /pipeline

USER pipeline

ENTRYPOINT ["nextflow", "run", "main.nf"]
CMD ["--help"]
