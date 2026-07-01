#!/usr/bin/env python3
# Run ESBMC-PLC-Sec on a PLC-Defuser dataset and classify each program's outcome
# honestly: parse-error, conversion-error, SAFE, VIOLATION, UNKNOWN, plus whether
# the FB-body translator fell back (unsupported ST constructs).
import sys, os, re, subprocess, glob, time, collections, tempfile
E=os.environ.get("ESBMC","esbmc")
_T=tempfile.mkdtemp(prefix="llb_")   # per-process temp dir (no cross-user collisions)
_P=os.path.join(_T,"p.yaml"); _L=os.path.join(_T,"run.ld")
DSROOT = sys.argv[1]          # e.g. .../pd/Datasets/SWAT
MODE_MAL = "--incremental-bmc"
# --ld-scan-watchdog/--ld-scan-budget are required since the scan-watchdog became
# opt-in; without them the non-termination payloads are not turned into violations.
FLAGS = ["--unwind","12","--no-pointer-check","--no-div-by-zero-check","--no-align-check",
         "--ld-scan-watchdog","--ld-scan-budget","8"]
# The sound Boolean/integer configuration is now a CLI flag (was the LLB_SOUND_MODE
# env var); honour the env so run_all.sh's convention keeps working with the merged binary.
if os.environ.get("LLB_SOUND_MODE"):
    FLAGS.append("--ld-sound-mode")

def bool_outvar(xml):
    txt = open(xml, errors="ignore").read()
    m = re.search(r"<outputVars>(.*?)</outputVars>", txt, re.S)
    if not m: return None
    for v in re.finditer(r'<variable name="([A-Za-z0-9_]+)">\s*<type>\s*<BOOL', m.group(1)):
        return v.group(1)
    return None

def classify(out):
    if "VERIFICATION SUCCESSFUL" in out: return "SAFE"
    if "VERIFICATION FAILED" in out:     return "VIOLATION"
    if "VERIFICATION UNKNOWN" in out:    return "UNKNOWN"
    if "PARSING ERROR" in out:           return "PARSE_ERR"
    if "CONVERSION ERROR" in out:        return "CONV_ERR"
    return "OTHER"

def run(xml, kind):
    bv = bool_outvar(xml) or "ENO"
    prop = f'properties:\n  - id: P0\n    kind: invariant\n    expression: "{bv} || !{bv}"\n'
    open(_P,"w").write(prop)
    ld = _L; open(ld,"w").write(open(xml,errors="ignore").read())
    mode = MODE_MAL if kind=="mal" else "--k-induction"
    try:
        r = subprocess.run([E, ld, "--ld-props",_P, mode]+FLAGS,
                           capture_output=True, text=True, timeout=60)
        out = r.stdout + r.stderr
    except subprocess.TimeoutExpired:
        return "TIMEOUT", False
    fb_fallback = "not translated" in out
    return classify(out), fb_fallback

for kind,label in [("mal","malicious"),("leg","legitimate")]:
    xmls = sorted(glob.glob(f"{DSROOT}/{label}/**/plc.xml", recursive=True))
    res = collections.Counter(); fb = 0; t0=time.time()
    for x in xmls:
        v, fbk = run(x, kind)
        res[v]+=1; fb += int(fbk)
    dt=time.time()-t0
    print(f"\n[{os.path.basename(DSROOT)} / {label}]  n={len(xmls)}  ({dt:.0f}s)")
    for k,c in res.most_common(): print(f"   {k:10s} {c}")
    print(f"   (FB-body fallback in {fb} programs)")
