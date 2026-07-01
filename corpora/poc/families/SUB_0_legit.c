extern int nondet_int(void);
int SUB_0(int IN1, int IN2){
  int OUT=IN1 - IN2;
  return OUT;
}
int main(void){ int IN1=nondet_int(),IN2=nondet_int(); return SUB_0(IN1,IN2); }
