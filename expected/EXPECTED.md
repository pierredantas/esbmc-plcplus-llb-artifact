# Expected results (reference)

Measured on Apple Silicon (aarch64, macOS), ESBMC v8.3.0 + Z3, with the modeling layer.
Exact times vary by machine; verdicts/counts should match.

## Two configurations (one binary, CLI flag)
- **`--ld-sound-mode`** — *sound Boolean/integer*: no over-approximation; zero false
  positives. Used for RQ2, RQ4, RQ5.
- **default (flag omitted)** — *analog-extended*: over-approximates unsupported ST
  constructs so analog SWaT programs can be modelled, at the cost of soundness. Used for RQ6.
- The scan-watchdog is opt-in: pass **`--ld-scan-watchdog --ld-scan-budget 8`** to turn
  non-termination payloads into reachable violations (required for RQ1/RQ2/RQ5/RQ6).
`run_all.sh` sets the right flags per experiment automatically.

## PoC (no datasets) — `corpora/poc/families/gen_run_families.sh`
```
FAMILY  LEGIT  MALICIOUS  TRIG
EQ_0    SAFE   VIOLATION  12
LE_0    SAFE   VIOLATION  12
LT_0    SAFE   VIOLATION  12
GE_0    SAFE   VIOLATION  12
GT_0    SAFE   VIOLATION  12
SUB_0   SAFE   VIOLATION  25
```

## RQ2 — Iacobelli Water_tank (30+30), sound Boolean/integer config
```
malicious  : VIOLATION 30
legitimate : SAFE 29, UNKNOWN 1        (0 false positives)
```

## RQ4 — Adaptive adversary (`02_adaptive.sh`)
```
VARIANT        CFG-proxy   ESBMC
B0_baseline    FLAGGED     VIOLATION
E1_computed    missed      VIOLATION
E2_square      missed      VIOLATION
E3_factored    missed      VIOLATION
E4_temporal    missed      VIOLATION
=> proxy 1/5, ESBMC 5/5
```

## RQ5 — Scale corpus (`03_scale.sh`)
```
MALICIOUS TP=155 FN=0 ; BENIGN TN=155 FP=0   (median ~70 ms/program)
```

## RQ6 — PLC-Defuser SWaT (150+150), analog-extended config — two corpus versions
Two difficulty tiers of the same benchmark; both pinned by `00_fetch_datasets.sh`.

**v1.0.0 (Zenodo 10.5281/zenodo.14014820) — linear-trigger bombs:**
```
timer             50/50
particular_input  50/50
fault_code        49/50      (1 parse failure)
TOTAL             149/150 (99%)   legit: 0 false positives
sound config:     75/150          (drops __TRY/__CATCH + some timer; conservative)
```
**dev snapshot (commit 0361129) — adds nonlinear (i*i) bombs:**
```
timer             50/50
particular_input  12/50      (nonlinear-float SMT timeout)
fault_code        11/50      (nonlinear-integer SMT timeout)
TOTAL             73/150 (49%)    legit: 0 false positives within budget
```
On the linear v1.0.0 corpus ESBMC matches detection-tool performance (99%, 0 FP); on the
nonlinear dev corpus it is **behind** PLC-Defuser (~100% vs 49%), the gap being
nonlinear-arithmetic non-termination, fundamental to SMT-based detection.

## RQ7 — Regression (run separately on the ESBMC-PLC+ artifact benchmarks)
```
13/13 inherited benchmarks reproduce their original verdicts.
```
