#!/usr/bin/env bash
# =============================================================================
# Reproduce the paper "Detecting Ladder Logic Bombs in IEC 61131-3 PLC Programs
# using ESBMC-PLC+".  Set ESBMC to a built ESBMC-PLC+ binary WITH the modeling
# layer applied (src/modeling_layer.patch) — see REQUIREMENTS.md.
#
#   ESBMC=/path/to/esbmc bash run_all.sh
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
export ESBMC="${ESBMC:-esbmc}"
if ! "$ESBMC" --version >/dev/null 2>&1; then
  echo "ERROR: ESBMC not runnable ('$ESBMC'). Set ESBMC=/path/to/esbmc-plc+ binary."; exit 1
fi
echo "ESBMC: $("$ESBMC" --version 2>&1 | head -1)"
echo "Note: ESBMC must be the ESBMC-PLC+ build WITH src/modeling_layer.patch applied."
echo

bash "$HERE/scripts/00_fetch_datasets.sh"
DS="$HERE/corpora/datasets"

# Configurations (one binary). The sound/analog mode is the --ld-sound-mode flag;
# the runners below translate the LLB_SOUND_MODE=1 env into that flag, so the
# convention still reads naturally:
#   sound  (LLB_SOUND_MODE=1): Boolean/integer, zero false positives  -> RQ2, RQ4, RQ5
#   analog (unset)           : parses analog SWaT, over-approximates   -> RQ6
# The scan-watchdog is opt-in and added by every runner that detects non-termination.
echo; echo "#### RQ2 — Detection on third-party Iacobelli data (Water_tank 30+30) [SOUND] ####"
ESBMC="$ESBMC" LLB_SOUND_MODE=1 python3 "$HERE/scripts/run_dataset.py" "$DS/PLC_Defuser_v1.0.0/Datasets/Water_tank"
echo "Expected: malicious 30 VIOLATION ; legitimate 29 SAFE + 1 UNKNOWN (sound config, 0 FP)"

echo; echo "#### RQ4 — Adaptive adversary (5 variants) [SOUND] ####"
LLB_SOUND_MODE=1 bash "$HERE/scripts/02_adaptive.sh"

echo; echo "#### RQ5 — Boolean/integer scale corpus (155+155) [SOUND] ####"
LLB_SOUND_MODE=1 bash "$HERE/scripts/03_scale.sh"

echo; echo "#### RQ6 — PLC-Defuser SWaT (150+150) [ANALOG], both corpus tiers ####"
echo "-- v1.0.0 (linear triggers): expected 149/150 (99%), 0 FP --"
ESBMC="$ESBMC" python3 "$HERE/scripts/run_swat_categories.py" "$DS/PLC_Defuser_v1.0.0/Datasets/SWAT"
echo "-- dev snapshot (adds nonlinear i*i bombs): expected ~73/150 (49%), 0 FP; NOT parity (~100% for PLC-Defuser) --"
ESBMC="$ESBMC" python3 "$HERE/scripts/run_swat_categories.py" "$DS/PLC_Defuser_dev/Datasets/SWAT"

echo; echo "#### Standalone proof-of-concept (no datasets needed) ####"
echo "  bash corpora/poc/families/gen_run_families.sh  (legit SAFE / malicious VIOLATION, triggers 12 & 25)"
echo; echo "Done. See expected/EXPECTED.md for the reference numbers."
