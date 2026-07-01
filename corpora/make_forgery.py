#!/usr/bin/env python3
# Minimal self-contained value-forgery (actuator-manipulation) bomb, no loop:
# a user FB drives two interlocked actuator outputs; the malicious variant forges
# BOTH true under a trigger value, violating mutual exclusion. Detection here is
# NOT via the scan-watchdog (there is no loop) but via a safety property on the
# wired FB output -> demonstrates generality beyond non-termination bombs.
TEMPLATE = '''<?xml version='1.0' encoding='utf-8'?>
<project xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <types>
    <dataTypes/>
    <pous>
      <pou name="program0" pouType="program">
        <interface>
          <inputVars>
            <variable name="TRIG"><type><INT/></type></variable>
          </inputVars>
          <outputVars>
            <variable name="OUT_A"><type><BOOL/></type></variable>
            <variable name="OUT_B"><type><BOOL/></type></variable>
          </outputVars>
        </interface>
        <body>
          <LD>
            <inVariable localId="1"><expression>TRIG</expression></inVariable>
            <block localId="2" typeName="Ctrl" instanceName="ctrl0">
              <inputVariables>
                <variable formalParameter="TRIG">
                  <connectionPointIn><connection refLocalId="1"/></connectionPointIn>
                </variable>
              </inputVariables>
              <outputVariables>
                <variable formalParameter="A"/>
                <variable formalParameter="B"/>
              </outputVariables>
            </block>
            <outVariable localId="3">
              <connectionPointIn><connection refLocalId="2" formalParameter="A"/></connectionPointIn>
              <expression>OUT_A</expression>
            </outVariable>
            <outVariable localId="4">
              <connectionPointIn><connection refLocalId="2" formalParameter="B"/></connectionPointIn>
              <expression>OUT_B</expression>
            </outVariable>
          </LD>
        </body>
      </pou>
      <pou name="Ctrl" pouType="functionBlock">
        <interface>
          <inputVars><variable name="TRIG"><type><INT/></type></variable></inputVars>
          <outputVars>
            <variable name="A"><type><BOOL/></type></variable>
            <variable name="B"><type><BOOL/></type></variable>
          </outputVars>
        </interface>
        <body>
          <ST><xhtml:p><![CDATA[__BODY__]]></xhtml:p></ST>
        </body>
      </pou>
    </pous>
  </types>
  <instances>
    <configurations>
      <configuration name="Config0">
        <resource name="Res0">
          <task name="task0" priority="0" interval="T#20ms">
            <pouInstance name="instance0" typeName="program0"/>
          </task>
        </resource>
      </configuration>
    </configurations>
  </instances>
</project>
'''
LEGIT = "A := TRIG > 5;\nB := TRIG <= 5;"
BOMB  = ("A := TRIG > 5;\nB := TRIG <= 5;\n"
         "if TRIG = 77 then\n  A := TRUE;\n  B := TRUE;\nend_if;")
open("FORGE_legit.ld","w").write(TEMPLATE.replace("__BODY__", LEGIT))
open("FORGE_bomb.ld","w").write(TEMPLATE.replace("__BODY__", BOMB))
print("wrote FORGE_legit.ld, FORGE_bomb.ld")
