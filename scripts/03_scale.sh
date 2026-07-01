#!/usr/bin/env bash
# RQ5 — Boolean/integer scale corpus (155 malicious + 155 benign).
# Expected: 100% recall, 0 false positives, median ~70 ms.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ESBMC="${ESBMC:?set ESBMC=/path/to/esbmc-plc+ binary}"
W="$HERE/corpora/_scale"; mkdir -p "$W"; cd "$W"
cp "$HERE/corpora/gen_corpus.py" .
python3 gen_corpus.py
# scan-watchdog is opt-in; the corpus includes non-termination payloads, so it is required.
F="--no-pointer-check --no-div-by-zero-check --no-align-check --ld-scan-watchdog --ld-scan-budget 8"
# sound Boolean/integer config is now a flag (was the LLB_SOUND_MODE env var).
[ -n "${LLB_SOUND_MODE:-}" ] && F="$F --ld-sound-mode"
v(){ grep -q "VERIFICATION FAILED" "$1" && echo VIOLATION || { grep -q "VERIFICATION SUCCESSFUL" "$1" && echo SAFE || echo UNKNOWN; }; }
TP=0; FN=0; TN=0; FP=0
while read stem trig pay; do
  [ -z "$stem" ] && continue
  "$ESBMC" "corpus/M_$stem.ld" --ld-props "corpus/$stem.yaml" --incremental-bmc --unwind 16 $F > m.log 2>&1
  "$ESBMC" "corpus/L_$stem.ld" --ld-props "corpus/$stem.yaml" --k-induction --unwind 8 $F > l.log 2>&1
  [ "$(v m.log)" = VIOLATION ] && TP=$((TP+1)) || FN=$((FN+1))
  [ "$(v l.log)" = SAFE ] && TN=$((TN+1)) || FP=$((FP+1))
done < corpus/manifest.txt
echo "Scale corpus: MALICIOUS TP=$TP FN=$FN ; BENIGN TN=$TN FP=$FP"
echo "Expected: TP=155 FN=0 ; TN=155 FP=0"
