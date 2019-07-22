<Pattern>
  <Program>
    <Assignment id="memory" value="SM"/>
    <Instrument id="TCLK,TDI,TDO,TMS,pa">
      <Instruction id="genVec" value="6"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.dummy_str"/>
      <Instruction id="genVec" value="2"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.dummy_str"/>
      <Instruction id="genVec" value="1"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.dummy_str"/>
      <Instruction id="genVec" value="2"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.subr_test"/>
      <Instruction id="genVec" value="20"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.label_test"/>
      <Instruction id="genVec" value="1">
        <Assignment id="repeat" value="39"/>
      </Instruction>
      <Instruction id="genVec" value="1"/>
      <Instruction id="patternCall" value="OrigenTesters.patterns.global_label_test"/>
      <Instruction id="genVec" value="40"/>
    </Instrument>
  </Program>
  <Vector>
    XXXXXXX
    11H1XXX
    11H1XXX
    11H1XXX
    11H1XXX
    11H1XXX
    11H1XXX
    11H1001
    11H1001
    11H1001
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1111
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
    11H1101
  </Vector>
  <Comment>
    0 should get a repeat count added to this vector for digsrc start minimum distance
    1 R4 should get a repeat 5 vector
    2 R3 
    3 R2 
    4 R1 
    5 should get a send microcode and 1 cycle with D
    6 should get a cycle with D and no send----regular cycle with no D or send
    7 cycle with 001 on pa
    8 send microcode followed by DDD on pa----cycle with 001 on pa
    9 send microcode, DDD on pa with repeat 5 (will send 5 sets of data)----cycle with 001 on pa
    10 (overlay keeps)
    11 R19 
    12 R18 
    13 R17 
    14 R16 
    15 R15 
    16 R14 
    17 R13 
    18 R12 
    19 R11 
    20 R10 
    21 R9 
    22 R8 
    23 R7 
    24 R6 
    25 R5 
    26 R4 
    27 R3 
    28 R2 
    29 R1 
    33 R20 
    34 R19 
    35 R18 
    36 R17 
    37 R16 
    38 R15 
    39 R14 
    40 R13 
    41 R12 
    42 R11 
    43 R10 
    44 R9 
    45 R8 
    46 R7 
    47 R6 
    48 R5 
    49 R4 
    50 R3 
    51 R2 
    52 R1 
    53 R20 Now kick the tires of handshake overlay
    54 R19 
    55 R18 
    56 R17 
    57 R16 
    58 R15 
    59 R14 
    60 R13 
    61 R12 
    62 R11 
    63 R10 
    64 R9 
    65 R8 
    66 R7 
    67 R6 
    68 R5 
    69 R4 
    70 R3 
    71 R2 
    72 R1 
  </Comment>
</Pattern>
