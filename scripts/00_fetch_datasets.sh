#!/usr/bin/env bash
# Fetch the public third-party datasets (not redistributed here; downloaded at run
# time to respect their licenses).
#   - Iacobelli et al. PLC-LD-dataset (Water_tank, 30+30)        [RQ2]
#   - PLC-Defuser SWaT corpus (150+150)                          [RQ6]
#
# IMPORTANT (reproducibility): RQ6 reports TWO corpus versions that form two
# difficulty tiers, so we pin BOTH explicitly rather than tracking GitHub HEAD
# (which drifts):
#   - PLC_Defuser_v1.0.0  : archived Zenodo release (DOI 10.5281/zenodo.14014820);
#                           linear-trigger bombs        -> 149/150 detection.
#   - PLC_Defuser_dev     : commit 0361129c1fc3a0b55d63f1df2bdd66897fb7f4ba;
#                           adds nonlinear (i*i) bombs   -> 73/150 detection.
# Both are downloaded/checked out at fixed points so the RQ6 numbers reproduce.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DS="$HERE/corpora/datasets"; mkdir -p "$DS"

# --- Iacobelli et al. dataset (RQ2), vendored frozen at commit c2ee2324 -------
# Bundled in the artifact so RQ2 reproduces without depending on a HEAD clone. If
# the frozen copy is present we verify its integrity; otherwise fall back to a
# pinned clone.
IAC_COMMIT="c2ee23242361f5e9f17bdfc47991edc176a420b9"
if [ -f "$DS/PLC-LD-dataset/SHA256SUMS" ]; then
  echo "Using bundled Iacobelli dataset (verifying integrity)..."
  ( cd "$DS/PLC-LD-dataset" && shasum -a 256 -c SHA256SUMS >/dev/null ) \
    && echo "  integrity OK (60 files)" \
    || { echo "  ERROR: frozen Iacobelli dataset failed checksum verification" >&2; exit 1; }
elif [ ! -d "$DS/PLC-LD-dataset" ]; then
  echo "Frozen copy missing; cloning Iacobelli dataset @ ${IAC_COMMIT:0:7}..."
  git clone https://github.com/UniboSecurityResearch/PLC-LD-dataset.git "$DS/PLC-LD-dataset"
  git -C "$DS/PLC-LD-dataset" checkout -q "$IAC_COMMIT"
fi

# --- PLC-Defuser SWaT v1.0.0 (RQ6, linear tier), pinned to Zenodo ------------
PD_ZIP_URL="https://zenodo.org/api/records/14014820/files/UniboSecurityResearch/PLC_Defuser-v1.0.0.zip/content"
if [ ! -d "$DS/PLC_Defuser_v1.0.0" ]; then
  tmp="$(mktemp -d)"
  echo "Downloading PLC-Defuser v1.0.0 (Zenodo 10.5281/zenodo.14014820)..."
  curl -sL "$PD_ZIP_URL" -o "$tmp/PLC_Defuser-v1.0.0.zip"
  unzip -q "$tmp/PLC_Defuser-v1.0.0.zip" -d "$tmp"
  # The archive extracts to a single top-level dir (UniboSecurityResearch-PLC_Defuser-<sha>/);
  # normalise it so downstream paths stay stable.
  extracted="$(find "$tmp" -maxdepth 1 -type d -name 'UniboSecurityResearch-PLC_Defuser-*' | head -1)"
  mv "$extracted" "$DS/PLC_Defuser_v1.0.0"
  rm -rf "$tmp"
fi

# --- PLC-Defuser dev snapshot (RQ6, nonlinear tier) --------------------------
# This corpus is VENDORED (frozen) in the artifact at $DS/PLC_Defuser_dev because
# it is an unreleased GitHub commit that could be force-pushed/rebased away. If
# the frozen copy is present we verify its integrity and use it; only if it is
# absent do we fall back to cloning the pinned commit from GitHub.
PD_DEV_COMMIT="0361129c1fc3a0b55d63f1df2bdd66897fb7f4ba"
if [ -f "$DS/PLC_Defuser_dev/SHA256SUMS" ]; then
  echo "Using bundled PLC-Defuser dev snapshot (verifying integrity)..."
  ( cd "$DS/PLC_Defuser_dev" && shasum -a 256 -c SHA256SUMS >/dev/null ) \
    && echo "  integrity OK (300 files)" \
    || { echo "  ERROR: frozen dev corpus failed checksum verification" >&2; exit 1; }
elif [ ! -d "$DS/PLC_Defuser_dev" ]; then
  echo "Frozen copy missing; cloning PLC-Defuser dev snapshot @ ${PD_DEV_COMMIT:0:7}..."
  git clone https://github.com/UniboSecurityResearch/PLC_Defuser.git "$DS/PLC_Defuser_dev"
  git -C "$DS/PLC_Defuser_dev" checkout -q "$PD_DEV_COMMIT"
fi

echo "Datasets in $DS:"
echo "  Iacobelli Water_tank malicious:     $(find "$DS/PLC-LD-dataset/malicious" -name '*.xml' | wc -l | tr -d ' ')"
echo "  PLC-Defuser SWaT v1.0.0 malicious:  $(find "$DS/PLC_Defuser_v1.0.0/Datasets/SWAT/malicious" -name plc.xml | wc -l | tr -d ' ')  (linear tier)"
echo "  PLC-Defuser SWaT dev    malicious:  $(find "$DS/PLC_Defuser_dev/Datasets/SWAT/malicious"    -name plc.xml | wc -l | tr -d ' ')  (nonlinear tier, commit ${PD_DEV_COMMIT:0:7})"
echo "  (Both pinned; do NOT switch to a plain HEAD clone — the corpus drifts.)"
