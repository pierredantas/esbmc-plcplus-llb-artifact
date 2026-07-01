#!/usr/bin/env python3
# CFG-triage PROXY: a transparent model of a syntactic/structural LLB trigger-
# identification heuristic (the candidate-trigger step that approaches such as
# PLC-Defuser run before model checking).  It flags the canonical Ladder Logic
# Bomb signature: an INPUT variable equality-compared to a CONSTANT LITERAL in a
# branch guard that directly governs a payload (a loop / output override).
# It is NOT PLC-Defuser; it is a conservative, reproducible stand-in to show that
# any trigger-triage based on syntactic pattern is evadable, whereas a full
# semantic checker (ESBMC-PLC-Sec) is not.
import sys, re, xml.etree.ElementTree as ET

def fb_bodies(path):
    txt = open(path).read()
    return re.findall(r"<!\[CDATA\[(.*?)\]\]>", txt, re.S)

def flags_bomb(path):
    for body in fb_bodies(path):
        b = body.lower()
        # find every "if <var> = <int literal> then" guard
        for m in re.finditer(r"if\s+([a-z_]\w*)\s*=\s*(\d+)\s+then", b):
            seg = b[m.end(): b.find("end_if", m.end()) if "end_if" in b[m.end():] else len(b)]
            # payload directly governed by the literal-trigger guard?
            if "while" in seg or seg.count(":=") >= 2:
                return True, f"{m.group(1)} = {m.group(2)} -> payload"
    return False, ""

if __name__ == "__main__":
    for p in sys.argv[1:]:
        flagged, why = flags_bomb(p)
        print(f"{p.split('/')[-1]:28s} CFG-triage: {'FLAGGED' if flagged else 'missed ':8s} {why}")
