<Pattern>
  <Program>
    <Assignment id="memory" value="SM"/>
    <Instrument id="nvm_reset,nvm_clk,nvm_clk_mux,porta,portb,nvm_invoke,nvm_done,nvm_fail,nvm_alvtst,nvm_ahvtst,nvm_dtst,TCLK,TRST">
      <Instruction id="genVec" value="38"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.sub1"/>
      <Instruction id="genVec" value="1"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.sub2"/>
      <Instruction id="genVec" value="9"/>
      <Instruction id="match" value="1737"/>
      <Instruction id="genVec" value="8"/>
      <Instruction id="matchRepeat" value="8"/>
      <Instruction id="genVec" value="8"/>
      <Instruction id="genVec" value="8"/>
      <Instruction id="loop" value="11"/>
      <Instruction id="genVec" value="1"/>
      <Instruction id="genVec" value="1">
        <Assignment id="repeat" value="6015"/>
      </Instruction>
      <Instruction id="returnConditional">
        <Assignment id="onFail" value="false"/>
        <Assignment id="resetFail" value="false"/>
      </Instruction>
      <Instruction id="genVec" value="1"/>
      <Instruction id="genVec" value="1">
        <Assignment id="repeat" value="6015"/>
      </Instruction>
      <Instruction id="returnConditional">
        <Assignment id="onFail" value="false"/>
        <Assignment id="resetFail" value="false"/>
      </Instruction>
      <Instruction id="loopEnd"/>
      <Instruction id="genVec" value="3"/>
      <Instruction id="loop" value="3"/>
      <Instruction id="genVec" value="2"/>
      <Instruction id="loopEnd"/>
      <Instruction id="loop" value="5"/>
      <Instruction id="genVec" value="2"/>
      <Instruction id="loopEnd"/>
      <Instruction id="genVec" value="14"/>
    </Instrument>
  </Program>
  <Vector>
    11100000000000000000HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000000HLXXX01
    11100000000000000001HLXXX01
    11100000000000000000HLXXX01
    11100000000000000001HLXXX01
    11100000000000000000HLXXX01
    11100000000000000001HLXXX01
    11100000000000000000HLXXX01
    11100000000000000001HLXXX01
    11100000000000000000HLXXX01
    11100000000000000001HLXXX01
    11101010101000000001HLXXX01
    111HLHLHLHL000000001HLXXX01
    11101010101000000001HLXXX01
    111XXXXXXXX000000001HLXXX01
    11111111111000000001HLXXX01
    11122222222000000001HLXXX01
    11100000000000000001HLXXX01
    111HHHHHHHH000000001HLXXX01
    111LLLLLLLL000000001HLXXX01
    11100000000000000001HCXXX01
    11100000000000000001HLXXX01
    111CCCCCCCC000000001HCXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HCXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001HLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001HXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XLXXX01
    11100000000000000001XXXXX01
    11100000000000000001HLXXX01
    11110101010000000001XLXXX01
    11101010101000000001XLXXX01
    11110101010000000001XLXXX01
    11101010101000000001XLXXX01
    11110101010000000001XLXXX01
    11101010101000000001XLXXX01
    11101010101000000001XHXXX01
    11101010101000000001XXXXX01
    11101010101000000001XXXXX01
    11101010101000000001XXXXX01
    11101010101000000001XXXXX01
    11101010101000000001XXXXX01
    11101010101000000001XXXXX01
    11101010101000000001XXXXX01
    11101010101000000001XXXXX01
    11101010101000000001XXXXX01
    11101010101000000001XXXXX01
    11101010101000000001XHXXX01
    11101010101000000001XHXXX01
    11101010101000000000XHXXX01
  </Vector>
  <Comment>
    0 Test that basic cycling works
    1 R10 
    2 R9 
    3 R8 
    4 R7 
    5 R6 
    6 R5 
    7 R4 
    8 R3 
    9 R2 
    10 R1 
    21 Test that the port API works
    30 Test that the store method works----This vector should capture the FAIL pin data
    32 This vector should capture the FAIL pin and the PORTA data
    33 R3 
    34 R2 
    35 R1 
    36 This vector should capture the FAIL pin data
    37 Test calling a subroutine----This vector should call subroutine 'sub1'
    38 This vector should call subroutine 'sub2'
    40 R8 Test a single pin match loop----Wait for a maximum of 5.0ms----for the NVM_DONE pin to go HIGH
    41 R7 
    42 R6 
    43 R5 
    44 R4 
    45 R3 
    46 R2 
    47 R1 
    48 R8 
    49 R7 
    50 R6 
    51 R5 
    52 R4 
    53 R3 
    54 R2 
    55 R1 
    64 R8 
    65 R7 
    66 R6 
    67 R5 
    68 R4 
    69 R3 
    70 R2 
    71 R1 
    72 Test a two pin match loop----Wait for a maximum of 5.0ms----for the NVM_DONE pin to go HIGH----or the NVM_FAIL pin to go LOW----Check if NVM_DONE is HIGH yet
    73 Wait for failure to propagate
    74 Exit match loop if pin has matched (no error), otherwise clear error and remain in loop----Check if NVM_FAIL is LOW yet
    75 Wait for failure to propagate
    76 Exit match loop if pin has matched (no error), otherwise clear error and remain in loop----To get here something has gone wrong, strobe again to force a pattern failure
    77 Test looping, these vectors should be executed once
    79 Test looping, these vectors should be executed 3 times
    81 Test looping, these vectors should be executed 5 times
    83 Test suspend compares
    84 R10 The fail pin should not be compared on these vectors
    85 R9 
    86 R8 
    87 R7 
    88 R6 
    89 R5 
    90 R4 
    91 R3 
    92 R2 
    93 R1 
    94 And now it should
    95 Test inhibit vectors and comments----The invoke pin should be driving high on this cycle
    96 This should be the last thing you see until 'Inhibit complete!'----Inhibit complete!----The invoke pin should be driving low on this cycle
  </Comment>
</Pattern>
