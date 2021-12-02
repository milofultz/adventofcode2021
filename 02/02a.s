include "64cube.inc"

enum $00                        ; Declare memory for variables
  memory rBYTE 2                ; Pointer to memory address
  number rBYTE 1                ; Amount to be added/subtracted with operation
  operation rBYTE 1             ; Type of operation (up, down, forward)
  depth rBYTE 2                 ; Current depth
  distance rBYTE 2              ; Current distance traveled
  product rBYTE 2               ; Temp for multiplication subroutine
  down rBYTE 1                  ; Semantics for operations
  forward rBYTE 1
  up rBYTE 1
ende

enum $10
  finalAnswer rBYTE 3           ; For multiplying depth by distance
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
  sta depth
  sta depth + 1
  sta distance
  sta distance + 1
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

PerformOperation:
  lda operation
  cmp down                      ; If operation was down,
  beq GoDeeper                  ;   Increase depth by number
  cmp up                        ; Else if operation was up,
  beq GoShallower               ;   Decrease depth by number
                                ; Else, increase distance by number
  lda number
  clc
  adc distance + 1
  sta distance + 1
  lda #0
  adc distance
  sta distance
  jmp CompleteOperation

  GoDeeper:
  lda number
  clc
  adc depth + 1
  sta depth + 1
  lda #0
  adc depth
  sta depth
  jmp CompleteOperation

  GoShallower:
  lda depth + 1
  sec
  sbc number
  sta depth + 1
  lda depth
  sbc #0
  sta depth

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
  lda depth + 1                 ; Add depth LSD to finalAnswer LSD
  adc finalAnswer + 2
  sta finalAnswer + 2
  lda depth                     ; Add depth MSD to finalAnswer SD (with carry)
  adc finalAnswer + 1
  sta finalAnswer + 1
  lda #0                        ; Add #0 to finalAnswer MSD (with carry)
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
