FUNCTION_BLOCK OPEN_REQUEST
  VAR_INPUT
    IN1 : DINT;
    IN2 : DINT;
  END_VAR
  VAR_OUTPUT
    OUT : BOOL;
  END_VAR
  VAR
    exc : __SYSTEM.ExceptionCode;
  END_VAR
__TRY
OUT:=FALSE;
IF IN1=IN2 THEN
  OUT:=TRUE;
END_IF;
__CATCH(exc)
    OUT:=TRUE;
__ENDTRY;
END_FUNCTION_BLOCK

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
    _TMP_GE12_ENO : BOOL;
    _TMP_GE12_OUT : BOOL;
    _TMP_LE13_ENO : BOOL;
    _TMP_LE13_OUT : BOOL;
  END_VAR

  _TMP_GE12_OUT := GE(EN := TRUE, IN1 := level, IN2 := high_3, ENO => _TMP_GE12_ENO);
  high := _TMP_GE12_OUT;
  _TMP_LE13_OUT := LE(EN := TRUE, IN1 := level, IN2 := low_3, ENO => _TMP_LE13_ENO);
  low := _TMP_LE13_OUT;
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
    _TMP_GE11_ENO : BOOL;
    _TMP_GE11_OUT : BOOL;
    _TMP_LE10_ENO : BOOL;
    _TMP_LE10_OUT : BOOL;
  END_VAR

  _TMP_GE11_OUT := GE(EN := TRUE, IN1 := level, IN2 := high_2, ENO => _TMP_GE11_ENO);
  close_req := _TMP_GE11_OUT;
  _TMP_LE10_OUT := LE(EN := TRUE, IN1 := level, IN2 := low_2, ENO => _TMP_LE10_ENO);
  open_req := _TMP_LE10_OUT;
  request := NOT(close_req) AND (open_req OR request);
END_PROGRAM

PROGRAM PLC1
  VAR_INPUT
    level : DINT;
    request : DINT;
  END_VAR
  VAR_OUTPUT
    pumps : BOOL;
    valve : BOOL;
    open_req : BOOL;
  END_VAR
  VAR
    low : BOOL;
    high : BOOL;
    close_req : BOOL;
    low_1 : DINT := 40;
    high_1 : DINT := 80;
    OPEN_REQUEST0 : OPEN_REQUEST;
    _TMP_LE3_ENO : BOOL;
    _TMP_LE3_OUT : BOOL;
    _TMP_GE7_ENO : BOOL;
    _TMP_GE7_OUT : BOOL;
    _TMP_EQ24_ENO : BOOL;
    _TMP_EQ24_OUT : BOOL;
  END_VAR

  _TMP_LE3_OUT := LE(EN := TRUE, IN1 := level, IN2 := low_1, ENO => _TMP_LE3_ENO);
  low := _TMP_LE3_OUT;
  _TMP_GE7_OUT := GE(EN := TRUE, IN1 := level, IN2 := high_1, ENO => _TMP_GE7_ENO);
  high := _TMP_GE7_OUT;
  pumps := NOT(high) AND (low OR pumps);
  valve := NOT(close_req) AND (valve OR open_req AND NOT(low));
  _TMP_EQ24_OUT := EQ(EN := TRUE, IN1 := request, IN2 := 0, ENO => _TMP_EQ24_ENO);
  close_req := _TMP_EQ24_OUT;
  OPEN_REQUEST0(EN := TRUE, IN1 := 1, IN2 := request);
  IF OPEN_REQUEST0.ENO THEN
      open_req := OPEN_REQUEST0.OUT;
  END_IF;
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
