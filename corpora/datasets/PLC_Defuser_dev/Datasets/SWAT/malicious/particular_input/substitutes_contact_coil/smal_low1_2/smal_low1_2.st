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

FUNCTION_BLOCK LE_0
  VAR_INPUT
    IN1 : REAL;
    IN2 : REAL;
  END_VAR
  VAR_OUTPUT
    OUT : BOOL;
  END_VAR
  VAR
    i : REAL;
  END_VAR

  OUT:=FALSE;
  IF IN1<=IN2 THEN
    OUT:=TRUE;
  END_IF;
  i:=IN1-20.0;
  IF IN1=20.0 THEN
    while i<4.0 do
      OUT:=TRUE;
      i := i * i;
    end_while;
  end_if;
END_FUNCTION_BLOCK

PROGRAM PLC1
  VAR_INPUT
    level : REAL;
    request : DINT;
  END_VAR
  VAR_OUTPUT
    pumps : BOOL;
    valve : BOOL;
    low : BOOL;
  END_VAR
  VAR
    high : BOOL;
    open_req : BOOL;
    close_req : BOOL;
    low_1 : REAL := 40.0;
    high_1 : REAL := 80.0;
    LE_00 : LE_0;
    _TMP_GE3_ENO : BOOL;
    _TMP_GE3_OUT : BOOL;
    _TMP_EQ23_ENO : BOOL;
    _TMP_EQ23_OUT : BOOL;
    _TMP_EQ24_ENO : BOOL;
    _TMP_EQ24_OUT : BOOL;
  END_VAR

  _TMP_GE3_OUT := GE(EN := TRUE, IN1 := level, IN2 := high_1, ENO => _TMP_GE3_ENO);
  high := _TMP_GE3_OUT;
  pumps := NOT(high) AND (low OR pumps);
  valve := NOT(close_req) AND (valve OR open_req AND NOT(low));
  _TMP_EQ23_OUT := EQ(EN := TRUE, IN1 := request, IN2 := 1, ENO => _TMP_EQ23_ENO);
  open_req := _TMP_EQ23_OUT;
  _TMP_EQ24_OUT := EQ(EN := TRUE, IN1 := request, IN2 := 0, ENO => _TMP_EQ24_ENO);
  close_req := _TMP_EQ24_OUT;
  LE_00(EN := TRUE, IN1 := level, IN2 := low_1);
  IF LE_00.ENO THEN
      low := LE_00.OUT;
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

(*DBG:char md5[] = "8be0ba47d58ea06360ebcc032e2186d8";*)
(*DBG:/**)
(*DBG: * This file is part of OpenPLC Runtime*)
(*DBG: **)
(*DBG: * Copyright (C) 2023 Autonomy, GP Orcullo*)
(*DBG: * Based on the work by GP Orcullo on Beremiz for uC*)
(*DBG: **)
(*DBG: * This program is free software; you can redistribute it and/or*)
(*DBG: * modify it under the terms of the GNU General Public License*)
(*DBG: * as published by the Free Software Foundation; either version 2*)
(*DBG: * of the License, or (at your option) any later version.*)
(*DBG: **)
(*DBG: * This program is distributed in the hope that it will be useful,*)
(*DBG: * but WITHOUT ANY WARRANTY; without even the implied warranty of*)
(*DBG: * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the*)
(*DBG: * GNU General Public License for more details.*)
(*DBG: **)
(*DBG: * You should have received a copy of the GNU General Public License*)
(*DBG: * along with this program; If not, see <http://www.gnu.org/licenses/>.*)
(*DBG: **)
(*DBG: */*)
(*DBG:*)
(*DBG:#include <stdbool.h>*)
(*DBG:*)
(*DBG:#include "iec_types_all.h"*)
(*DBG:#include "POUS.h"*)
(*DBG:*)
(*DBG:#define SAME_ENDIANNESS      0*)
(*DBG:#define REVERSE_ENDIANNESS   1*)
(*DBG:*)
(*DBG:uint8_t endianness;*)
(*DBG:*)
(*DBG:*)
(*DBG:extern PLC1 RES0__INSTANCE0;*)
(*DBG:extern PLC2 RES0__INSTANCE1;*)
(*DBG:extern PLC3 RES0__INSTANCE2;*)
(*DBG:*)
(*DBG:static const struct {*)
(*DBG:    void *ptr;*)
(*DBG:    __IEC_types_enum type;*)
(*DBG:} debug_vars[] = {*)
(*DBG:    {&(RES0__INSTANCE0.LEVEL), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.REQUEST), DINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PUMPS), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.VALVE), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LOW), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.HIGH), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.OPEN_REQ), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.CLOSE_REQ), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LOW_1), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.HIGH_1), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LE_00.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LE_00.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LE_00.IN1), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LE_00.IN2), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LE_00.OUT), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LE_00.I), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._TMP_GE3_ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._TMP_GE3_OUT), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._TMP_EQ23_ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._TMP_EQ23_OUT), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._TMP_EQ24_ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._TMP_EQ24_OUT), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1.LEVEL), DINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1.REQUEST), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1.OPEN_REQ), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1.CLOSE_REQ), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1.LOW_2), DINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1.HIGH_2), DINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1._TMP_GE11_ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1._TMP_GE11_OUT), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1._TMP_LE10_ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE1._TMP_LE10_OUT), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2.LEVEL), DINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2.PUMP), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2.LOW), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2.HIGH), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2.LOW_3), DINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2.HIGH_3), DINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2._TMP_GE12_ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2._TMP_GE12_OUT), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2._TMP_LE13_ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE2._TMP_LE13_OUT), BOOL_ENUM},*)
(*DBG:};*)
(*DBG:*)
(*DBG:#define VAR_COUNT               42*)
(*DBG:*)
(*DBG:uint16_t get_var_count(void)*)
(*DBG:{*)
(*DBG:    return VAR_COUNT;*)
(*DBG:}*)
(*DBG:*)
(*DBG:size_t get_var_size(size_t idx)*)
(*DBG:{*)
(*DBG:    if (idx >= VAR_COUNT)*)
(*DBG:    {*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:    switch (debug_vars[idx].type) {*)
(*DBG:    case DINT_ENUM:*)
(*DBG:        return sizeof(DINT);*)
(*DBG:    case REAL_ENUM:*)
(*DBG:        return sizeof(REAL);*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return sizeof(BOOL);*)
(*DBG:    default:*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void *get_var_addr(size_t idx)*)
(*DBG:{*)
(*DBG:    void *ptr = debug_vars[idx].ptr;*)
(*DBG:*)
(*DBG:    switch (debug_vars[idx].type) {*)
(*DBG:    case DINT_ENUM:*)
(*DBG:        return (void *)&((__IEC_DINT_t *) ptr)->value;*)
(*DBG:    case REAL_ENUM:*)
(*DBG:        return (void *)&((__IEC_REAL_t *) ptr)->value;*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return (void *)&((__IEC_BOOL_t *) ptr)->value;*)
(*DBG:    default:*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void force_var(size_t idx, bool forced, void *val)*)
(*DBG:{*)
(*DBG:    void *ptr = debug_vars[idx].ptr;*)
(*DBG:*)
(*DBG:    if (forced) {*)
(*DBG:        size_t var_size = get_var_size(idx);*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case DINT_ENUM: {*)
(*DBG:            memcpy(&((__IEC_DINT_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_DINT_t *) ptr)->value = *((DINT *) val);*)
(*DBG:            ((__IEC_DINT_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case REAL_ENUM: {*)
(*DBG:            memcpy(&((__IEC_REAL_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_REAL_t *) ptr)->value = *((REAL *) val);*)
(*DBG:            ((__IEC_REAL_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case BOOL_ENUM: {*)
(*DBG:            memcpy(&((__IEC_BOOL_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_BOOL_t *) ptr)->value = *((BOOL *) val);*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    } else {*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case DINT_ENUM:*)
(*DBG:            ((__IEC_DINT_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case REAL_ENUM:*)
(*DBG:            ((__IEC_REAL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case BOOL_ENUM:*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void swap_bytes(void *ptr, size_t size) *)
(*DBG:{*)
(*DBG:    uint8_t *bytePtr = (uint8_t *)ptr;*)
(*DBG:    size_t i;*)
(*DBG:    for (i = 0; i < size / 2; ++i) *)
(*DBG:    {*)
(*DBG:        uint8_t temp = bytePtr[i];*)
(*DBG:        bytePtr[i] = bytePtr[size - 1 - i];*)
(*DBG:        bytePtr[size - 1 - i] = temp;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void trace_reset(void)*)
(*DBG:{*)
(*DBG:    for (size_t i=0; i < VAR_COUNT; i++) *)
(*DBG:    {*)
(*DBG:        force_var(i, false, 0);*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void set_trace(size_t idx, bool forced, void *val)*)
(*DBG:{*)
(*DBG:    if (idx >= 0 && idx < VAR_COUNT) *)
(*DBG:    {*)
(*DBG:        if (endianness == REVERSE_ENDIANNESS)*)
(*DBG:        {*)
(*DBG:            // Aaaaarghhhh... Stupid AVR is Big Endian.*)
(*DBG:            swap_bytes(val, get_var_size(idx));*)
(*DBG:        }*)
(*DBG:*)
(*DBG:        force_var(idx, forced, val);*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void set_endianness(uint8_t value)*)
(*DBG:{*)
(*DBG:    if (value == SAME_ENDIANNESS || value == REVERSE_ENDIANNESS)*)
(*DBG:    {*)
(*DBG:        endianness = value;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)