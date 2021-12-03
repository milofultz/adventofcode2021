include "64cube.inc"

enum $00                        ; Declare memory for variables
  memory rBYTE 2                ; Pointer to memory address
  total rBYTE 2                 ; Total numbers seen
  product rBYTE 3               ; Temp for multiplication subroutine
  gamma rBYTE 2
  epsilon rBYTE 2
ende

enum $10
  bits rBYTE 24                  ; For tallying bit counts
ende

enum $30
  zero rBYTE 1                  ; For semantics
  newline rBYTE 1
ende

  org $200
  sei
  ldx #$ff                      ; Set the stack
  txs

  _setw IRQ, VBLANK_IRQ

  ; $30-39 = 0-9
  ; $0a    = LF (\n)
  lda #$30                      ; Set semantics for operations to ASCII code
  sta zero
  lda #$0a
  sta newline
  lda #$30                      ; Init `memory` to #$3000
  sta memory + 1
  lda #0                        ; Zero all vars
  sta memory
  sta gamma + 1
  sta gamma
  sta epsilon + 1
  sta epsilon
  sta bits
  sta bits + 1
  sta bits + 2
  sta bits + 3
  sta bits + 4
  sta bits + 5
  sta bits + 6
  sta bits + 7
  sta bits + 8
  sta bits + 9
  sta bits + 10
  sta bits + 11
  sta bits + 12
  sta bits + 13
  sta bits + 14
  sta bits + 15
  sta bits + 16
  sta bits + 17
  sta bits + 18
  sta bits + 19
  sta bits + 20
  sta bits + 21
  sta bits + 22
  sta bits + 23
  tax
  tay

  cli

Part1:
  GetNextBit:
  inx
  ldy #0
  lda ($00),y                   ; Load next number into accumulator
  beq EndOfInput                ; If end of input, complete program

  jsr IncMemory                 ; Else, increment memory
  cmp newline                   ; If char is a newline,
  beq ResetForNextBits          ;   Reset for next set of bits
  cmp zero                      ; Else if number is not zero,
  bne IncBit                    ;   Increment that bit
  jmp GetNextBit                ; Else, get the next bit

  ResetForNextBits:
  ldx #0                        ; Reset bit counter
  clc
  inc total + 1
  bne SkipIncTotalMSD
  inc total
  SkipIncTotalMSD:
  jmp GetNextBit                ; Get the next number

  IncBit:
  txa
  asl
  tay
  dey
  clc
  lda #1
  adc bits,y
  sta bits,y
  dey
  lda #0
  adc bits,y
  sta bits,y
  jmp GetNextBit

IncMemory:
  inc memory                    ; Increment the memory LSD pointer
  bne ReturnFromIncMemory       ; If pointer doesn't exceed $ff, continue
  inc memory + 1                ; Increment MSD
  ReturnFromIncMemory:
  rts

EndOfInput:
  jmp CalculateAnswer

MultiplyGandE:
  ; gamma   = Iterator
  ; epsilon = Factor

  lda #0
  sta product + 2
  sta product + 1
  sta product                   ; Zero out product variable

  WhileMult:
  sec
  lda gamma + 1
  sbc #1
  sta gamma + 1
  lda gamma
  sbc #0
  sta gamma                     ; Decrement gamma

  clc
  lda epsilon + 1
  adc product + 2
  sta product + 2
  lda epsilon
  adc product + 1
  sta product + 1
  lda #0
  adc product
  sta product                   ; Add epsilon to product

  lda gamma + 1
  bne WhileMult
  lda gamma
  bne WhileMult                 ; If gamma is not zero, continue loop

  rts                           ; Else, return from subroutine

CalculateAnswer:
  ror total                     ; Halve total values for comparison
  ror total + 1

  ldy #0                        ; Set Y to 0

  WhileBits:
  clc
  rol gamma + 1
  rol gamma
  clc
  rol epsilon + 1
  rol epsilon                   ; Shift all bits over one to the left
  sec
  lda total
  cmp bits,y                    ; If number MSD at bit is > total numbers,
  iny                           ; (Have to place this here for proper branching)
  bcc SetGamma                  ;   Set gamma bit
  lda total + 1
  cmp bits,y                    ; If number LSD at bit is >
  beq SetGamma                  ;     or === total numbers,
  bcc SetGamma                  ;   Set gamma bit
                                ; Else,
  SetEpsilon:                   ;   Set epsilon bit
  inc epsilon + 1
  jmp CheckY

  SetGamma:
  inc gamma + 1

  CheckY:
  iny
  cpy #24                       ; If y is not 24,
  bne WhileBits                 ;    Continue
                                ; Else,
  jsr MultiplyGandE             ; Multiply gamma and epsilon together

  jmp ProgramComplete

Infinite:
  jmp Infinite
ProgramComplete:
  jmp ProgramComplete


IRQ:
  rti

  org $3000
  ;incbin "roms/aoc2021/03/ins2.raw"
  ;incbin "roms/aoc2021/03/ins1.raw"
  incbin "roms/aoc2021/03/in.raw"
