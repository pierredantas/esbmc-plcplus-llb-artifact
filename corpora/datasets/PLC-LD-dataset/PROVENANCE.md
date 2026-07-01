# Iacobelli et al. PLC-LD-dataset — frozen copy (RQ2)

Frozen copy of the third-party Iacobelli et al. Ladder-Diagram LLB dataset,
vendored here so RQ2 reproduces independently of the upstream GitHub repository.

- **Upstream:** https://github.com/UniboSecurityResearch/PLC-LD-dataset
- **Commit:** `c2ee23242361f5e9f17bdfc47991edc176a420b9` (2024-10-30)
- **Frozen on:** 2026-06-26
- **Contents:** 30 malicious + 30 legitimate PLCopen LD programs (Water-treatment
  process; bombs are `EQ`/`LT`/`LE`/`GE`/`GT` comparison-block triggers with
  coil/assignment payloads). Used for RQ2 (third-party detection).
- **License:** GPL-3.0 (see `LICENSE`); verbatim copy, no modifications. Cite per
  `CITATION.cff`.

See `SHA256SUMS` for integrity. RQ2 reference result (sound Boolean/integer
configuration): 30/30 malicious detected; 29 SAFE + 1 UNKNOWN benign; 0 false
positives.
