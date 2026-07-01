# PLC-Defuser SWaT — frozen development snapshot (RQ6, nonlinear tier)

This directory is a **frozen copy** of the SWaT corpus from the PLC-Defuser
repository, vendored here so the RQ6 *nonlinear* tier reproduces independently of
the upstream GitHub repository (which continues to evolve and could be
force-pushed/rebased).

- **Upstream:** https://github.com/UniboSecurityResearch/PLC_Defuser
- **Commit:** `0361129c1fc3a0b55d63f1df2bdd66897fb7f4ba` (2026-06-03)
- **Frozen on:** 2026-06-26
- **Contents:** `Datasets/SWAT/` only — 150 malicious (timer / particular_input /
  fault_code) + 150 legitimate PLCopen LD programs. This version adds
  **nonlinear-arithmetic** non-termination bombs (`i := i*i`) absent from the
  archived Zenodo v1.0.0 release.
- **License:** GPL-3.0 (see `LICENSE`). Redistributed here under its terms; this
  is a verbatim copy of the upstream dataset with no modifications.

## Why this is separate from v1.0.0
The paper's RQ6 reports **two tiers** of the same benchmark:
- **v1.0.0** (Zenodo DOI 10.5281/zenodo.14014820): linear-trigger bombs → 149/150 (99%).
- **dev snapshot** (this directory): adds nonlinear bombs → 73/150 (49%).

The archived v1.0.0 release contains **no** nonlinear arithmetic; the 49% result
is specific to this development snapshot. See `SHA256SUMS` for integrity.
