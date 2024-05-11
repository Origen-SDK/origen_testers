<Pattern>
  <Program>
    <Assignment id="memory" value="SM"/>
    <Instrument id="nvm_reset,nvm_clk,nvm_clk_mux,porta,portb,nvm_invoke,nvm_done,nvm_fail,nvm_alvtst,nvm_ahvtst,nvm_dtst,TCLK,TRST">
      <Instruction id="genVec" value="38"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.sub1"/>
      <Instruction id="genVec" value="1"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.sub2"/>
      <Instruction id="genVec" value="9"/>
      <Instruction id="match" value="7813">
         <Assignment id="matchMode" value="stopOnFail"/>
      </Instruction>
      <Instruction id="genVec" value="8"/>
      <Instruction id="matchRepeat" value="8"/>
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
      <Instruction id="genVec" value="9"/>
      <Instruction id="match" value="7813">
         <Assignment id="matchMode" value="stopOnFail"/>
      </Instruction>
      <Instruction id="genVec" value="8"/>
      <Instruction id="matchRepeat" value="8"/>
      <Instruction id="genVec" value="2"/>
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
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001HLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XLXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001HXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XLXXX01
    11100000000000000001XXXXX01
    11100000000000000001HLXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001HHXXX01
    11100000000000000001HHXXX01
    11100000000000000001HHXXX01
    11100000000000000001HHXXX01
    11100000000000000001HHXXX01
    11100000000000000001HHXXX01
    11100000000000000001HHXXX01
    11100000000000000001HHXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11100000000000000001XXXXX01
    11110101010000000001HHXXX01
    11101010101000000001HHXXX01
    11110101010000000001HHXXX01
    11101010101000000001HHXXX01
    11110101010000000001HHXXX01
    11101010101000000001HHXXX01
    11101010101000000001HHXXX01
    11101010101000000001HXXXX01
    11101010101000000001HXXXX01
    11101010101000000001HXXXX01
    11101010101000000001HXXXX01
    11101010101000000001HXXXX01
    11101010101000000001HXXXX01
    11101010101000000001HXXXX01
    11101010101000000001HXXXX01
    11101010101000000001HXXXX01
    11101010101000000001HXXXX01
    11101010101000000001HHXXX01
    11101010101000000001HHXXX01
    11101010101000000000HHXXX01
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
    49 R7 
    50 R6 
    51 R5 
    52 R4 
    53 R3 
    54 R2 
    55 R1 
    56 R8 
    57 R7 
    58 R6 
    59 R5 
    60 R4 
    61 R3 
    62 R2 
    63 R1 
    64 Test a two pin match loop----Wait for a maximum of 5.0ms----for the NVM_DONE pin to go HIGH----or the NVM_FAIL pin to go LOW
    65 Wait for failure to propagate
    66 Exit match loop if pin has matched (no error), otherwise clear error and remain in loop
    67 Wait for failure to propagate
    68 Exit match loop if pin has matched (no error), otherwise clear error and remain in loop----To get here something has gone wrong, strobe again to force a pattern failure
    69 R8 Test a block match loop----Wait for a maximum of 5.0ms
    70 R7 
    71 R6 
    72 R5 
    73 R4 
    74 R3 
    75 R2 
    76 R1 
    77 R8 
    78 R7 
    79 R6 
    80 R5 
    81 R4 
    82 R3 
    83 R2 
    84 R1 
    85 R8 
    86 R7 
    87 R6 
    88 R5 
    89 R4 
    90 R3 
    91 R2 
    92 R1 
    93 Test looping, these vectors should be executed once
    95 Test looping, these vectors should be executed 3 times
    97 Test looping, these vectors should be executed 5 times
    99 Test suspend compares
    100 R10 The fail pin should not be compared on these vectors
    101 R9 
    102 R8 
    103 R7 
    104 R6 
    105 R5 
    106 R4 
    107 R3 
    108 R2 
    109 R1 
    110 And now it should
    111 Test inhibit vectors and comments----The invoke pin should be driving high on this cycle
    112 This should be the last thing you see until 'Inhibit complete!'----Inhibit complete!----The invoke pin should be driving low on this cycle
  </Comment>
</Pattern>
