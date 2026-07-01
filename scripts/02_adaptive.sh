#!/usr/bin/env bash
# RQ4 — adaptive adversary: 5 trigger-hiding variants; CFG-triage PROXY vs ESBMC-PLC+.
# Expected: proxy flags 1/5 (only the literal baseline); ESBMC detects 5/5.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ESBMC="${ESBMC:?set ESBMC=/path/to/esbmc-plc+ binary}"
DS="$HERE/corpora/datasets/PLC-LD-dataset"
W="$HERE/corpora/_adaptive"; mkdir -p "$W/ds"; cd "$W"
ln -sfn "$DS/malicious" ds/malicious
cp "$HERE/corpora/gen_adaptive.py" "$HERE/corpora/cfg_triage_proxy.py" .
python3 gen_adaptive.py >/dev/null
printf 'properties:\n  - id: P0\n    kind: invariant\n    expression: "CYCLE_ON || !CYCLE_ON"\n' > p.yaml
# scan-watchdog is opt-in; the adaptive EQ_0 bomb is non-terminating, so it is required.
FLAGS="--no-pointer-check --no-div-by-zero-check --no-align-check --ld-scan-watchdog --ld-scan-budget 8"
# sound Boolean/integer config is now a flag (was the LLB_SOUND_MODE env var).
[ -n "${LLB_SOUND_MODE:-}" ] && FLAGS="$FLAGS --ld-sound-mode"
printf "%-22s | %-10s | %-10s\n" "VARIANT" "CFG-proxy" "ESBMC"
printf -- "-----------------------+------------+-----------\n"
ndet=0
for v in B0_baseline E1_computed E2_square E3_factored E4_temporal; do
  cf=$(python3 cfg_triage_proxy.py "ADV_$v.ld" 2>/dev/null | grep -oE "FLAGGED|missed")
  uw=12; [ "$v" = E4_temporal ] && uw=20
  "$ESBMC" "ADV_$v.ld" --ld-props p.yaml --incremental-bmc --unwind "$uw" $FLAGS > "$v.log" 2>&1
  if grep -qi "VERIFICATION FAILED" "$v.log"; then ev="VIOLATION"; ndet=$((ndet+1)); else ev="SAFE/UNK"; fi
  printf "%-22s | %-10s | %-10s\n" "$v" "$cf" "$ev"
done
echo "ESBMC detected $ndet/5  (expected 5/5; CFG-triage proxy expected 1/5)"
