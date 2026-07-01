FUNCTION_BLOCK handler_pumps
  VAR_INPUT
    IN1 : DINT;
    IN2 : DINT;
    IN3 : DINT;
  END_VAR
  VAR_OUTPUT
    OUT1 : BOOL;
    OUT2 : BOOL;
  END_VAR
  VAR
    i : INT;
    mytimer : TON;
  END_VAR

  OUT1:=FALSE;
  OUT2:=FALSE;
  IF IN2 = IN1 then
    OUT1:=TRUE;
  END_IF;
  IF IN2 = IN3 then
    OUT2:=TRUE;
  END_IF;
  mytimer(IN := TRUE, PT := t#8000ms);
  i:=0;
  IF mytimer.Q = TRUE then
     WHILE i<4 do
      OUT1:=TRUE;
    End_WHILE;
  End_IF;
   
END_FUNCTION_BLOCK

PROGRAM PLC1
  VAR_INPUT
    level : DINT;
    request : DINT;
  END_VAR
  VAR_OUTPUT
    pumps : BOOL;
    valve : BOOL;
  END_VAR
  VAR
    low : BOOL;
    high : BOOL;
    open_req : BOOL;
    close_req : BOOL;
    low_1 : DINT := 40;
    high_1 : DINT := 80;
    handler_pumps0 : handler_pumps;
    _TMP_LE31_ENO : BOOL;
    _TMP_LE31_OUT : BOOL;
    _TMP_GE32_ENO : BOOL;
    _TMP_GE32_OUT : BOOL;
  END_VAR

  _TMP_LE31_OUT := LE(EN := TRUE, IN1 := level, IN2 := low_1, ENO => _TMP_LE31_ENO);
  low := _TMP_LE31_OUT;
  _TMP_GE32_OUT := GE(EN := TRUE, IN1 := level, IN2 := high_1, ENO => _TMP_GE32_ENO);
  high := _TMP_GE32_OUT;
  handler_pumps0(EN := TRUE, IN1 := 1, IN2 := request, IN3 := 0);
  open_req := handler_pumps0.OUT1;
  close_req := handler_pumps0.OUT2;
  pumps := NOT(high) AND (low OR pumps);
  valve := NOT(close_req) AND (open_req AND NOT(low) OR valve);
END_PROGRAM

PROGRAM PLC3
  VAR_INPUT
    level : DINT;
  END_VAR
  VAR_OUTPUT
    pump : BOOL;
  END_VAR
  VAR
    low : BOOL;
    high : BOOL;
    low_3 : DINT := 0;
    high_3 : DINT := 10;
    _TMP_LE13_ENO : BOOL;
    _TMP_LE13_OUT : BOOL;
    _TMP_GE12_ENO : BOOL;
    _TMP_GE12_OUT : BOOL;
  END_VAR

  _TMP_LE13_OUT := LE(EN := TRUE, IN1 := level, IN2 := low_3, ENO => _TMP_LE13_ENO);
  low := _TMP_LE13_OUT;
  _TMP_GE12_OUT := GE(EN := TRUE, IN1 := level, IN2 := high_3, ENO => _TMP_GE12_ENO);
  high := _TMP_GE12_OUT;
  pump := NOT(low) AND (high OR pump);
END_PROGRAM

PROGRAM PLC2
  VAR_INPUT
    level : DINT;
  END_VAR
  VAR_OUTPUT
    request : BOOL;
  END_VAR
  VAR
    open_req : BOOL;
    close_req : BOOL;
    low_2 : DINT := 10;
    high_2 : DINT := 20;
    _TMP_LE10_ENO : BOOL;
    _TMP_LE10_OUT : BOOL;
    _TMP_GE11_ENO : BOOL;
    _TMP_GE11_OUT : BOOL;
  END_VAR

  _TMP_LE10_OUT := LE(EN := TRUE, IN1 := level, IN2 := low_2, ENO => _TMP_LE10_ENO);
  open_req := _TMP_LE10_OUT;
  _TMP_GE11_OUT := GE(EN := TRUE, IN1 := level, IN2 := high_2, ENO => _TMP_GE11_ENO);
  close_req := _TMP_GE11_OUT;
  request := NOT(close_req) AND (open_req OR request);
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    TASK task1(INTERVAL := T#20ms,PRIORITY := 0);
    TASK task2(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : PLC1;
    PROGRAM instance1 WITH task1 : PLC2;
    PROGRAM instance2 WITH task2 : PLC3;
  END_RESOURCE
END_CONFIGURATION
