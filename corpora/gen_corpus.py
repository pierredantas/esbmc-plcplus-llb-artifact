#!/usr/bin/env python3
# Generate a large, taxonomy-complete LLB benchmark corpus (legit/malicious pairs)
# spanning {trigger class} x {payload class} x {parameter variation}, at the scale
# of the PLC-Defuser evaluation (150+150). Each program is a minimal PLCopen XML
# LD with one user FB driving two interlocked actuators; the malicious variant
# injects a trigger-gated payload. Fully reproducible.
import os, itertools, pathlib
OUT = pathlib.Path("corpus"); OUT.mkdir(exist_ok=True)

TEMPLATE = '''<?xml version='1.0' encoding='utf-8'?>
<project xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <types><dataTypes/><pous>
    <pou name="program0" pouType="program">
      <interface>
        <inputVars><variable name="TRIG"><type><INT/></type></variable></inputVars>
        <outputVars>
          <variable name="OUT_A"><type><BOOL/></type></variable>
          <variable name="OUT_B"><type><BOOL/></type></variable>
        </outputVars>
      </interface>
      <body><LD>
        <inVariable localId="1"><expression>TRIG</expression></inVariable>
        <block localId="2" typeName="Ctrl" instanceName="ctrl0">
          <inputVariables><variable formalParameter="TRIG">
            <connectionPointIn><connection refLocalId="1"/></connectionPointIn></variable></inputVariables>
          <outputVariables><variable formalParameter="A"/><variable formalParameter="B"/></outputVariables>
        </block>
        <outVariable localId="3"><connectionPointIn><connection refLocalId="2" formalParameter="A"/></connectionPointIn><expression>OUT_A</expression></outVariable>
        <outVariable localId="4"><connectionPointIn><connection refLocalId="2" formalParameter="B"/></connectionPointIn><expression>OUT_B</expression></outVariable>
      </LD></body>
    </pou>
    <pou name="Ctrl" pouType="functionBlock">
      <interface>
        <inputVars><variable name="TRIG"><type><INT/></type></variable></inputVars>
        <outputVars>
          <variable name="A"><type><BOOL/></type></variable>
          <variable name="B"><type><BOOL/></type></variable></outputVars>
        <localVars><variable name="i"><type><INT/></type></variable>
          <variable name="k"><type><INT/></type></variable>
          <variable name="cnt"><type><INT/></type></variable></localVars>
      </interface>
      <body><ST><xhtml:p><![CDATA[__BODY__]]></xhtml:p></ST></body>
    </pou>
  </pous></types>
  <instances><configurations><configuration name="Config0"><resource name="Res0">
    <task name="task0" priority="0" interval="T#20ms"><pouInstance name="instance0" typeName="program0"/></task>
  </resource></configuration></configurations></instances>
</project>
'''

BASE = "A := TRIG > {th};\nB := TRIG <= {th};\n"

# trigger classes: each wraps a payload so it fires iff TRIG == K (hidden forms)
def t_literal(K, p):   return f"if TRIG = {K} then\n{p}\nend_if;"
def t_computed(K, p):  return f"k := {K-3} + 3;\nif TRIG = k then\n{p}\nend_if;"
def t_square(K, p):    return f"if TRIG * TRIG = {K*K} then\n{p}\nend_if;"
def t_factored(K, p):  return f"if (TRIG - {K}) * (TRIG - {K}) = 0 then\n{p}\nend_if;"
def t_range(K, p):     return f"if TRIG >= {K} then\n if TRIG <= {K} then\n{p}\n end_if;\nend_if;"
def t_temporal(K, p):  return f"if TRIG = {K} then\n cnt := cnt + 1;\nend_if;\nif cnt >= 3 then\n{p}\nend_if;"
TRIGGERS = {"literal":t_literal, "computed":t_computed, "square":t_square,
            "factored":t_factored, "range":t_range, "temporal":t_temporal}

# payload classes
P_NONTERM = "i := 0;\n while i < 4 do\n  A := FALSE;\n end_while;"   # DoS  -> watchdog
P_FORGERY = "A := TRUE;\n B := TRUE;"                                # value -> mutual_excl
PAYLOADS = {"nonterm": P_NONTERM, "forgery": P_FORGERY}

PROP = {
  "nonterm": "  - id: P0\n    kind: invariant\n    expression: \"OUT_A || !OUT_A\"\n",
  "forgery": "  - id: MX\n    kind: mutual_exclusion\n    variables: [OUT_A, OUT_B]\n",
}

Ks = [12, 25, 33, 47, 58, 64, 77, 88, 91, 103, 119, 126, 140]  # 13 trigger constants
count = 0
manifest = []
for (tname, tfun), (pname, pcode), K in itertools.product(TRIGGERS.items(), PAYLOADS.items(), Ks):
    th = (K % 7) + 3
    base = BASE.format(th=th)
    legit = base
    bomb  = base + tfun(K, pcode)
    stem = f"{tname}_{pname}_K{K}"
    (OUT/f"L_{stem}.ld").write_text(TEMPLATE.replace("__BODY__", legit))
    (OUT/f"M_{stem}.ld").write_text(TEMPLATE.replace("__BODY__", bomb))
    (OUT/f"{stem}.yaml").write_text("properties:\n" + PROP[pname])
    manifest.append((stem, tname, pname, pname=="nonterm"))
    count += 1
pathlib.Path(OUT/"manifest.txt").write_text("\n".join(f"{s} {t} {p}" for s,t,p,_ in manifest))
print(f"generated {count} malicious + {count} legit = {2*count} programs across "
      f"{len(TRIGGERS)} triggers x {len(PAYLOADS)} payloads x {len(Ks)} constants")
