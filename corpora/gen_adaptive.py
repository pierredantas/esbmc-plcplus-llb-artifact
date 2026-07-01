#!/usr/bin/env python3
# Generate adaptive-adversary variants of the EQ_0 bomb (mstart_eq.xml) whose
# trigger is hidden from a syntactic/CFG trigger-pattern heuristic but is
# semantically identical (detonates iff IN1 == 12).
import sys, re, pathlib
src = pathlib.Path("ds/malicious/mstart_eq.xml").read_text()

# the canonical bomb trigger+payload inside the EQ_0 ST body
BASE_TRIG = "if IN1 = 12 then"
assert src.count(BASE_TRIG) == 1, "trigger anchor not found uniquely"

variants = {
  # B0: baseline literal equality (the naive, detectable trigger)
  "B0_baseline":     "if IN1 = 12 then",
  # E1: trigger constant computed, never appears as a literal comparison
  "E1_computed":     "k:=5+7;\nif IN1 = k then",
  # E2: opaque arithmetic predicate (IN1*IN1 = 144  <=>  IN1 = +/-12)
  "E2_square":       "if IN1 * IN1 = 144 then",
  # E3: factored opaque predicate ((IN1-12)^2 = 0  <=>  IN1 = 12)
  "E3_factored":     "if (IN1 - 12) * (IN1 - 12) = 0 then",
}

for name, trig in variants.items():
    out = src.replace(BASE_TRIG, trig)
    pathlib.Path(f"ADV_{name}.ld").write_text(out)
    print(f"wrote ADV_{name}.ld")

# E4: multi-scan temporal trigger — payload gated by a persistent accumulator,
# so the per-scan input comparison (IN1=12) only increments a counter and the
# payload sits under a STATE comparison (arm>=3). Detonates after IN1==12 occurs
# 3 times across scans. Replace the whole payload block.
PAYLOAD = ("i:=0;\nif IN1 = 12 then\n  while i<4 do\n    OUT:=FALSE;\n"
           "  end_while;\n end_if;")
# fall back to a tolerant match if whitespace differs
m = re.search(r"i:=0;.*?end_if;", src, re.S)
assert m, "payload block not found"
e4_payload = ("if IN1 = 12 then\n  arm := arm + 1;\nend_if;\n"
              "i:=0;\nif arm >= 3 then\n  while i<4 do\n    OUT:=FALSE;\n"
              "  end_while;\nend_if;")
pathlib.Path("ADV_E4_temporal.ld").write_text(src[:m.start()] + e4_payload + src[m.end():])
print("wrote ADV_E4_temporal.ld")
