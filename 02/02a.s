include "64cube.inc"

enum $00                        ; Declare memory for variables
  memory rBYTE 2                ; Pointer to memory address
  number rBYTE 2                ; Amount to be added/subtracted with operation
  operation rBYTE 1             ; Type of operation (up, down, forward)
  depth rBYTE 2                 ; Current depth
  distance rBYTE 2              ; Current distance traveled
  product rBYTE 2               ; Temp for multiplication subroutine
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
  beq ProgramComplete           ; If end of input, complete program

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
  pha                           ; Save current number in stack
  jsr MultiplyBy10              ; Multiply current number by 10
  pla
  clc
  adc number + 1                ; Add current number to number * 10
  sta number + 1
  lda #0
  adc number                    ; Increment MSD if carry bit set
  jmp GetNumbers                ; Get the next number

Infinite:
  jmp Infinite
ProgramComplete:
  jmp ProgramComplete

IncMemory:
  inc memory                    ; Increment the memory pointer
  bne ReturnFromIncMemory       ; If pointer doesn't exceed $ff, continue
  inc memory + 1                ; Increment MSD
  ReturnFromIncMemory:
  rts

MultiplyBy10:
  ; IN:  number
  ; OUT: none (updated `number`)

  lda #0
  sta product + 1               ; Initialize product to 0
  sta product
  ldy #10                       ; Set iterator to 10
  lda number
  beq AddNumLSD

  AddNumMSD:
  lda number                    ; Put number MSD in accumulator
  clc
  adc product                   ; Sum product and number in accumulator

  StoreNewProductMSD:
  sta product                   ; Store new sum in product MSD
  dey                           ; Decrement iterator
  bne AddNumMSD                 ; If iterator is not zero, goto AddNumMSD

  ldy #10                       ; Set iterator to 10

  AddNumLSD:
  lda number + 1                ; Put number LSD in accumulator
  clc
  adc product + 1               ; Sum product and number in accumulator
  bcc StoreNewProductLSD        ; If sum didnt exceed #$ff, StoreNewProductLSD
  inc product                   ; Else, increment product MSD

  StoreNewProductLSD:
  sta product + 1               ; Store new sum in product LSD
  dey                           ; Decrement iterator
  bne AddNumLSD                 ; If iterator is not zero, goto AddNumLSD

  lda product
  sta number
  lda product + 1
  sta number + 1                ; Store product in number

  rts                           ; Return from subroutine

PerformOperation:
  lda operation
  cmp down                      ; If operation was down,
  beq GoDeeper                  ;   Increase depth by number
  cmp up                        ; Else if operation was up,
  beq GoShallower               ;   Decrease depth by number
                                ; Else, increase distance by number
  lda distance + 1
  clc
  adc number + 1
  sta distance + 1
  lda distance
  adc number
  sta distance
  jmp CompleteOperation

  GoDeeper:
  lda depth + 1
  clc
  adc number + 1
  sta depth + 1
  lda depth
  adc number
  sta depth
  jmp CompleteOperation

  GoShallower:
  lda depth + 1
  sec
  sbc number + 1
  sta depth + 1
  lda depth
  sbc number
  sta depth

  CompleteOperation:
  lda #0
  sta number
  sta number + 1                ; Reset current number to 0
  sta operation                 ; Reset operation to 0

  jsr IncMemory
  jmp GetNextDirection


IRQ:
  rti

  org $3000
  incbin "roms/aoc2021/02/ins1.raw"
  ;incbin "roms/aoc2021/02/in.raw"
