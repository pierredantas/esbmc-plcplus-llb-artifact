#!/usr/bin/env python3
import sys, re, subprocess, glob, collections, os, tempfile
E=os.environ.get("ESBMC","esbmc")
_T=tempfile.mkdtemp(prefix="llb_")   # per-process temp dir (no cross-user collisions)
_P=os.path.join(_T,"p.yaml"); _L=os.path.join(_T,"run.ld")
root=sys.argv[1]
# --ld-scan-watchdog/--ld-scan-budget are required since the scan-watchdog became
# opt-in; without them the non-termination payloads are not turned into violations.
F=["--unwind","10","--no-pointer-check","--no-div-by-zero-check","--no-align-check",
   "--ld-scan-watchdog","--ld-scan-budget","8"]
def bv(xml):
    t=open(xml,errors="ignore").read(); m=re.search(r"<outputVars>(.*?)</outputVars>",t,re.S)
    if m:
        v=re.search(r'<variable name="([A-Za-z0-9_]+)">\s*<type>\s*<BOOL',m.group(1))
        if v: return v.group(1)
    return "ENO"
def run(xml,mode):
    open(_P,"w").write(f'properties:\n  - id: P0\n    kind: invariant\n    expression: "{bv(xml)} || !{bv(xml)}"\n')
    open(_L,"w").write(open(xml,errors="ignore").read())
    try:
        o=subprocess.run([E,_L,"--ld-props",_P,mode]+F,capture_output=True,text=True,timeout=10)
        s=o.stdout+o.stderr
    except subprocess.TimeoutExpired: return "TIMEOUT"
    if "VERIFICATION FAILED" in s: return "VIOLATION"
    if "VERIFICATION SUCCESSFUL" in s: return "SAFE"
    if "VERIFICATION UNKNOWN" in s: return "UNKNOWN"
    return "ERR"
det=collections.Counter(); tot=collections.Counter()
for x in sorted(glob.glob(f"{root}/malicious/**/plc.xml",recursive=True)):
    c=re.search(r"/malicious/([^/]+)/",x).group(1); tot[c]+=1
    if run(x,"--incremental-bmc")=="VIOLATION": det[c]+=1
print("MAL by category:", flush=True)
for c in sorted(tot): print(f"  {c:18s} {det[c]}/{tot[c]}", flush=True)
print(f"  MAL TOTAL {sum(det.values())}/{sum(tot.values())}", flush=True)
fp=0; n=0
for x in sorted(glob.glob(f"{root}/legitimate/**/plc.xml",recursive=True)):
    n+=1
    if run(x,"--k-induction")=="VIOLATION": fp+=1
print(f"  LEG false-positives {fp}/{n}", flush=True)
print("DONE", flush=True)
