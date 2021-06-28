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
      <Instruction id="genVec" value="23"/>
      <Instruction id="genVec" value="1">
        <Assignment id="repeat" value="40"/>
      </Instruction>
      <Instruction id="genVec" value="43"/>
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
    11 R20 
    12 R19 
    13 R18 
    14 R17 
    15 R16 
    16 R15 
    17 R14 
    18 R13 
    19 R12 
    20 R11 
    21 R10 
    22 R9 
    23 R8 
    24 R7 
    25 R6 
    26 R5 
    27 R4 
    28 R3 
    29 R2 
    30 R1 
    31 label_test(1st line after local label for overlay)
    32 (2nd line after local label for overlay)
    33 (3rd line after local label for overlay)
    35 global_label_test(1st line after global label for overlay)
    36 (2nd line after global label for overlay)
    37 (3rd line after global label for overlay)
    38 R20 
    39 R19 
    40 R18 
    41 R17 
    42 R16 
    43 R15 
    44 R14 
    45 R13 
    46 R12 
    47 R11 
    48 R10 
    49 R9 
    50 R8 
    51 R7 
    52 R6 
    53 R5 
    54 R4 
    55 R3 
    56 R2 
    57 R1 
    58 R20 Now kick the tires of handshake overlay
    59 R19 
    60 R18 
    61 R17 
    62 R16 
    63 R15 
    64 R14 
    65 R13 
    66 R12 
    67 R11 
    68 R10 
    69 R9 
    70 R8 
    71 R7 
    72 R6 
    73 R5 
    74 R4 
    75 R3 
    76 R2 
    77 R1 
  </Comment>
</Pattern>
