# Artifact — Detecting Ladder Logic Bombs in IEC 61131-3 PLC Programs using ESBMC-PLC+

[![CI](https://github.com/pierredantas/esbmc-plcplus-llb-artifact/actions/workflows/ci.yml/badge.svg)](https://github.com/pierredantas/esbmc-plcplus-llb-artifact/actions/workflows/ci.yml)

Archived release: [10.5281/zenodo.20930052](https://doi.org/10.5281/zenodo.20930052)

> **Continuous integration.** [`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs
> two smoke-test jobs on every push: **validate** (lints the scripts, runs the corpus
> generators and checks their counts, and verifies the vendored datasets' checksums) and
> **poc** (downloads a pinned stock ESBMC binary and runs the six-family proof-of-concept —
> the PoC is plain C, so it detects each bomb and proves each benign variant SAFE *without*
> the modeling-layer patch or the ESBMC-PLC+ LD frontend). The full patched build
> (`Dockerfile`) is heavy and version-sensitive and is intentionally not run in CI.

This artifact reproduces the experiments in the paper. The method **uses ESBMC-PLC+**
(an existing IEC 61131-3 verifier) as its verification engine, **unchanged**, and adds a
**modeling layer** (`src/modeling_layer.patch`) that exposes function-block-resident
Ladder Logic Bomb (LLB) logic to the prover.

## Contents
```
artifact/
├── README.md            this file
├── REQUIREMENTS.md      how to obtain/build the ESBMC-PLC+ engine + apply the patch
├── LICENSE
├── run_all.sh           one-shot reproduction (set ESBMC=...)
├── src/
│   └── modeling_layer.patch   the modeling layer (apply to the ESBMC-PLC+ source)
├── scripts/
│   ├── 00_fetch_datasets.sh   fetch the public datasets at pinned versions
│   ├── run_dataset.py         RQ2 — generic dataset runner (confusion matrix)
│   ├── 02_adaptive.sh         RQ4 — adaptive adversary vs CFG-triage proxy
│   ├── 03_scale.sh            RQ5 — Boolean/integer scale corpus (155+155)
│   └── run_swat_categories.py RQ6 — PLC-Defuser SWaT (run per pinned version)
├── corpora/
│   ├── gen_corpus.py          generator for the 310-program scale corpus
│   ├── gen_adaptive.py        generator for the 5 adaptive variants
│   ├── cfg_triage_proxy.py    transparent model of CFG trigger triage
│   ├── make_forgery.py        value/actuator-forgery example (generality)
│   └── poc/                   standalone PoC (C transcriptions of the 6 FB bombs)
└── expected/EXPECTED.md       reference numbers each experiment should produce
```

## Quick start (existing ESBMC-PLC+ binary)
```bash
# 1. Build/obtain the ESBMC-PLC+ engine with the modeling layer (see REQUIREMENTS.md)
export ESBMC=/path/to/esbmc          # the patched ESBMC-PLC+ binary
# 2. Reproduce everything
bash run_all.sh
```
Individual experiments: `bash scripts/02_adaptive.sh`, `bash scripts/03_scale.sh`, etc.
The PoC needs no datasets: `bash corpora/poc/families/gen_run_families.sh`.

## From-scratch build (Docker, environment-independent)
`Dockerfile` builds ESBMC-PLC+ from source, applies `src/modeling_layer.patch`, and
bundles the harnesses — no local toolchain needed:
```bash
docker build -t llb-esbmc \
    --build-arg ESBMC_REPO=<git url of the ESBMC-PLC+ source> \
    --build-arg ESBMC_REF=<branch/tag/commit> .
docker run --rm -it llb-esbmc                 # dataset-free PoC (fast, no network)
docker run --rm -it llb-esbmc bash run_all.sh # full reproduction (needs network)
```
The patch targets ESBMC's LD frontend (`src/ld-frontend/`), so `ESBMC_REPO/REF` must
point at an ESBMC-PLC+ source containing it. The ESBMC build is heavy/version-sensitive;
validate the image once and pin versions if upstream changes.

## Claims ↔ experiments
| Paper claim | Script | Reference result |
|---|---|---|
| RQ2 third-party detection | `run_dataset.py` (Water_tank) | 30/30 malicious; 29 SAFE +1 UNKNOWN; 0 FP |
| RQ4 adaptive adversary | `02_adaptive.sh` | proxy 1/5, ESBMC 5/5 |
| RQ5 scale (Boolean/integer) | `03_scale.sh` | TP=155 FN=0; TN=155 FP=0 |
| RQ6 real SWaT (v1.0.0, linear) | `run_swat_categories.py` (`PLC_Defuser_v1.0.0`) | 149/150 (99%); 0 FP |
| RQ6 real SWaT (dev, nonlinear) | `run_swat_categories.py` (`PLC_Defuser_dev`) | 73/150 (timer 50/50); nonlinear timeout; behind PLC-Defuser |
| PoC (enabling) | `poc/families/gen_run_families.sh` | legit SAFE / malicious VIOLATION; triggers 12,25 |

## Honesty notes (also in the paper)
- Strong, sound results are the **Boolean/integer** configuration (RQ2, RQ5).
- The **analog-extended** configuration (used for SWaT, RQ6) over-approximates and can
  introduce a false positive. RQ6 runs on **two pinned versions** of the SWaT corpus:
  the archived **v1.0.0** (linear-trigger bombs) → 149/150 (99%), 0 FP; and a later
  **dev snapshot** (commit `0361129`, adds `i:=i*i` nonlinear bombs) → 49%, **not** parity
  with PLC-Defuser (~100%) because nonlinear non-termination times out in SMT.
- The scan-watchdog is **opt-in**: pass `--ld-scan-watchdog --ld-scan-budget 8`. The
  sound/analog toggle is the `--ld-sound-mode` flag (was the `LLB_SOUND_MODE` env var).
- The CFG-triage comparator (RQ4) is a transparent **model**, not PLC-Defuser itself.
- PLC-Defuser is pinned to two fixed versions, never a HEAD clone: **v1.0.0** is fetched
  at run time from its Zenodo DOI, and the **dev snapshot** (commit `0361129`) is bundled
  frozen under `corpora/datasets/PLC_Defuser_dev/` (GPL-3, redistributed verbatim with
  `LICENSE` + `PROVENANCE.md` + a `SHA256SUMS` integrity manifest), because that commit
  could be force-pushed away upstream. The **Iacobelli** dataset (RQ2, commit `c2ee2324`)
  is likewise bundled frozen under `corpora/datasets/PLC-LD-dataset/` (GPL-3, with
  `LICENSE`/`PROVENANCE.md`/`SHA256SUMS`). Both frozen corpora are checksum-verified by
  `00_fetch_datasets.sh`; only the stable Zenodo v1.0.0 archive is fetched at run time.
