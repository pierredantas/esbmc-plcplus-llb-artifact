# =============================================================================
# From-scratch BUILD reproduction (environment-independent).
#
# Builds ESBMC-PLC+ from source, applies the modeling layer (modeling_layer.patch),
# and bundles the experiment harnesses so the whole pipeline runs in any Docker host.
#
#   docker build -t llb-esbmc \
#       --build-arg ESBMC_REPO=<git url of your ESBMC-PLC+ source> \
#       --build-arg ESBMC_REF=<branch/tag/commit> .
#   docker run --rm -it llb-esbmc            # runs the dataset-free PoC by default
#   docker run --rm -it llb-esbmc bash run_all.sh   # full reproduction (needs network)
#
# NOTE (honesty): the ESBMC build is heavy and version-sensitive (Z3, clang/LLVM,
# Boost). The modeling layer patches the ESBMC *LD frontend* (the ESBMC-PLC+
# contribution), so ESBMC_REPO/REF MUST point at an ESBMC-PLC+ source that contains
# src/ld-frontend/. This Dockerfile follows ESBMC's documented Ubuntu build; validate
# it once and pin dependency versions if the upstream build flow changes.
# =============================================================================
FROM ubuntu:22.04

ARG ESBMC_REPO=https://github.com/esbmc/esbmc.git
ARG ESBMC_REF=master
ENV DEBIAN_FRONTEND=noninteractive

# --- build dependencies (per ESBMC's Ubuntu build instructions) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        git ca-certificates curl python3 python3-pip \
        build-essential cmake ninja-build \
        clang-14 llvm-14 llvm-14-dev libclang-14-dev \
        flex bison libboost-all-dev z3 libz3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
# --- get the ESBMC-PLC+ source and apply the modeling layer ---
RUN git clone --depth 1 --branch ${ESBMC_REF} ${ESBMC_REPO} esbmc
COPY src/modeling_layer.patch /opt/modeling_layer.patch
RUN cd esbmc && git apply /opt/modeling_layer.patch \
    && test -f src/ld-frontend/ir_gen/st_fb_translator.cpp   # sanity: patch applied

# --- build (adjust flags to your ESBMC-PLC+ build if needed) ---
RUN cd esbmc && mkdir -p build && cd build \
    && cmake .. -GNinja \
         -DCMAKE_BUILD_TYPE=Release \
         -DLLVM_DIR=/usr/lib/llvm-14/cmake \
         -DClang_DIR=/usr/lib/cmake/clang-14 \
         -DENABLE_Z3=ON \
    && ninja esbmc
ENV ESBMC=/opt/esbmc/build/src/esbmc/esbmc

# --- bundle the experiment harnesses ---
WORKDIR /artifact
COPY . /artifact
RUN chmod +x run_all.sh scripts/*.sh corpora/poc/families/*.sh 2>/dev/null || true

# default: the dataset-free proof-of-concept (fast, no network)
CMD ["bash", "-lc", "cd corpora/poc/families && bash gen_run_families.sh"]
