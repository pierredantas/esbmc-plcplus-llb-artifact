/* Faithful C transcription of the EQ_0 function block (the logic bomb)
   from Iacobelli PLC-LD-dataset malicious/mstart_eq.xml. */
extern int nondet_int(void);
_Bool EQ_0(int IN1, int IN2) {
    _Bool OUT = 0;
    if (IN1 == IN2) OUT = 1;        /* normal EQ behaviour */
    int i = 0;
    if (IN1 == 12) {                /* TRIGGER: secret value 12 */
        while (i < 4) {             /* PAYLOAD: i never incremented -> infinite loop (DoS) */
            OUT = 0;
        }
    }
    return OUT;
}
int main(void) {
    int IN1 = nondet_int(), IN2 = nondet_int();
    return (int) EQ_0(IN1, IN2);
}
