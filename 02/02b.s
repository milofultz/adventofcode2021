include "64cube.inc"

enum $00                        ; Declare memory for variables
  memory rBYTE 2                ; Pointer to memory address
  number rBYTE 1                ; Amount to be added/subtracted with operation
  operation rBYTE 1             ; Type of operation (up, down, forward)
  aim rBYTE 3                   ; Current aim
  depth rBYTE 4                 ; Current depth
  distance rBYTE 2              ; Current distance traveled
  product rBYTE 3               ; Temp for multiplication subroutine
ende

enum $10
  finalAnswer rBYTE 4           ; For multiplying depth by distance
  down rBYTE 1                  ; Semantics for operations
  forward rBYTE 1
  up rBYTE 1

ende

  org $200
  sei
  ldx #$ff                      ; Set the stack
  txs

  _setw IRQ, VBLANK_IRQ

  lda #$64                      ; Set semantics for operations to ASCII code
  sta down
  lda #$66
  sta forward
  lda #$75
  sta up
  lda #$30                      ; Init `memory` to #$3000
  sta memory + 1
  lda #0                        ; Zero all vars
  sta memory
  sta aim
  sta aim + 1
  sta aim + 2
  sta depth
  sta depth + 1
  sta depth + 2
  sta depth + 3
  sta distance
  sta distance + 1
  sta finalAnswer
  sta finalAnswer + 1
  sta finalAnswer + 2
  sta finalAnswer + 3
  tax
  tay

  cli

; $64    = d
; $66    = f
; $75    = u
; $30-39 = 0-9
; $0a    = LF (\n)

Part1:
  GetNextDirection:
  ldy #0
  lda ($00),y                   ; Load next operation into accumulator
  sta operation                 ; Store operation
  beq EndOfInput                ; If end of input, complete program

  SkipNonNumbers:
  jsr IncMemory
  ldy #0
  lda ($00),y                   ; Load next char into accumulator
  cmp #$20                      ; If char is not a space,
  bne SkipNonNumbers            ;   Get the next char
                                ; Else,
  GetNumbers:
  jsr IncMemory                 ; Get first number
  ldy #0
  lda ($00),y                   ; Load next number into accumulator
  cmp #$0a                      ; If newline,
  beq PerformOperation          ;   Perform operation with the number
                                ; Else,
  CompileNumber:
  sec
  sbc #$30                      ; Set accumulator to actual number
  sta number                    ; Store number
  jmp GetNumbers                ; Get the next number

IncMemory:
  inc memory                    ; Increment the memory pointer
  bne ReturnFromIncMemory       ; If pointer doesn't exceed $ff, continue
  inc memory + 1                ; Increment MSD
  ReturnFromIncMemory:
  rts

EndOfInput:
  jmp CalculateAnswer

MultiplyAim:
  ; X   = Iterator
  ; aim = Factor

  lda #0
  sta product + 2
  sta product + 1
  sta product

  WhileXMult:
  clc
  lda aim + 2
  adc product + 2
  sta product + 2
  lda aim + 1
  adc product + 1
  sta product + 1
  lda aim
  adc product
  sta product
  dex
  bne WhileXMult

  rts

PerformOperation:
  lda operation
  cmp down ; $64                ; If operation was down,
  beq IncAim                    ;   Increase aim by number
  cmp up   ; $66                ; Else if operation was up,
  beq DecAim                    ;   Decrease aim by number
                                ; Else, increase distance by number and
                                ;   increase depth by aim * number
  IncreaseDistance:
  lda number
  clc
  adc distance + 1
  sta distance + 1
  lda #0
  adc distance
  sta distance

  IncDepth:
  ldx number
  jsr MultiplyAim
  lda product + 2
  adc depth + 3
  sta depth + 3
  lda product + 1
  adc depth + 2
  sta depth + 2
  lda product
  adc depth + 1
  sta depth + 1
  lda #0
  adc depth
  sta depth
  jmp CompleteOperation

  IncAim:
  clc
  lda number
  adc aim + 2
  sta aim + 2
  lda #0
  adc aim + 1
  sta aim + 1
  lda #0
  adc aim
  sta aim
  jmp CompleteOperation

  DecAim:
  sec
  lda aim + 2
  sbc number
  sta aim + 2
  lda aim + 1
  sbc #0
  sta aim + 1
  lda aim
  sbc #0
  sta aim

  CompleteOperation:
  lda #0
  sta number                    ; Reset current number to 0
  sta operation                 ; Reset operation to 0

  jsr IncMemory
  jmp GetNextDirection

CalculateAnswer:
  ; Y = iterator MSD
  ; X = iterator LSD

  ldy distance                  ; Store distance MSD in Y
  ldx distance + 1              ; Store distance LSD in X

  iny                           ; Increment Y (for final beq check)

  WhileX:
  clc
  lda depth + 3                 ; Add depth LSD to finalAnswer LSD
  adc finalAnswer + 3
  sta finalAnswer + 3
  lda depth + 2                 ; Add depth MLSD to finalAnswer MLSD (withcarry)
  adc finalAnswer + 2
  sta finalAnswer + 2
  lda depth + 1                 ; Add depth MHSD to finalAnswer MHSD (withcarry)
  adc finalAnswer + 1
  sta finalAnswer + 1
  lda depth                     ; Add depth HSD to finalAnswer HSD (with carry)
  adc finalAnswer
  sta finalAnswer

  dex                           ; Decrement iterator LSD
  bne WhileX                    ; If X is not zero, continue loop

  dey                           ; Decrement iterator MSD
  beq ProgramComplete           ; If iterator MSD is zero, total is calculated
  jmp WhileX                    ; Continue addition

Infinite:
  jmp Infinite
ProgramComplete:
  jmp ProgramComplete


IRQ:
  rti

  org $3000
  ;incbin "roms/aoc2021/02/ins1.raw"
  incbin "roms/aoc2021/02/in.raw"
