#!/usr/bin/env bash
# Generalize the PoC across all 6 Iacobelli trigger families.
# Faithful C transcriptions of each derived-FB body; legit = same FB without the
# non-termination payload. ESBMC detects the bomb and recovers the trigger.
set -u
ESBMC="${ESBMC:-esbmc}"
OUT=fam; mkdir -p "$OUT"
# family : C-operator : trigger-const : payload-type
declare -a FAM=(
  "EQ_0:==:12:bool"
  "LE_0:<=:12:bool"
  "LT_0:<:12:bool"
  "GE_0:>=:12:bool"
  "GT_0:>:12:bool"
  "SUB_0:-:25:int"
)
gen () { # name op trig kind variant(legit|malicious)
  local name=$1 op=$2 trig=$3 kind=$4 var=$5 f="$OUT/${1}_${5}.c"
  if [ "$kind" = bool ]; then
    {
      echo 'extern int nondet_int(void);'
      echo "_Bool ${name}(int IN1, int IN2){"
      echo "  _Bool OUT=0;"
      echo "  if(IN1 ${op} IN2) OUT=1;"
      if [ "$var" = malicious ]; then
        echo "  int i=0;"
        echo "  if(IN1==${trig}){ while(i<4){ OUT=0; } }   /* non-termination bomb */"
      fi
      echo "  return OUT;"
      echo "}"
      echo "int main(void){ int IN1=nondet_int(),IN2=nondet_int(); return (int)${name}(IN1,IN2); }"
    } > "$f"
  else
    {
      echo 'extern int nondet_int(void);'
      echo "int ${name}(int IN1, int IN2){"
      echo "  int OUT=IN1 ${op} IN2;"
      if [ "$var" = malicious ]; then
        echo "  int i=0;"
        echo "  if(IN1==${trig}){ while(i<4){ OUT=${trig}; } }   /* non-termination bomb */"
      fi
      echo "  return OUT;"
      echo "}"
      echo "int main(void){ int IN1=nondet_int(),IN2=nondet_int(); return ${name}(IN1,IN2); }"
    } > "$f"
  fi
}
verdict () { grep -q "VERIFICATION SUCCESSFUL" "$1" && echo SAFE || { grep -q "VERIFICATION FAILED" "$1" && echo VIOLATION || echo UNKNOWN; }; }
trig_rec () { grep -oE 'IN1 = [0-9]+' "$1" | head -1 | sed -E 's/.*= //'; }

printf "%-7s | %-9s | %-11s | %-13s | %s\n" "FAMILY" "LEGIT" "MALICIOUS" "EXPECT-TRIG" "RECOVERED-TRIG"
printf -- "--------+-----------+-------------+---------------+----------------\n"
for spec in "${FAM[@]}"; do
  IFS=: read -r name op trig kind <<< "$spec"
  gen "$name" "$op" "$trig" "$kind" legit
  gen "$name" "$op" "$trig" "$kind" malicious
  ll="$OUT/${name}_legit.log"; ml="$OUT/${name}_malicious.log"
  "$ESBMC" "$OUT/${name}_legit.c"     --unwind 10 --z3 > "$ll" 2>&1
  "$ESBMC" "$OUT/${name}_malicious.c" --unwind 10 --z3 > "$ml" 2>&1
  printf "%-7s | %-9s | %-11s | %-13s | %s\n" \
    "$name" "$(verdict "$ll")" "$(verdict "$ml")" "IN1=$trig" "IN1=$(trig_rec "$ml")"
done
