extern int nondet_int(void);
_Bool GT_0(int IN1, int IN2){
  _Bool OUT=0;
  if(IN1 > IN2) OUT=1;
  return OUT;
}
int main(void){ int IN1=nondet_int(),IN2=nondet_int(); return (int)GT_0(IN1,IN2); }
