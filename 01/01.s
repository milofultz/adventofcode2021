include "64cube.inc"

enum $00                        ; Declare memory for variables
  memory rBYTE 2
  count rBYTE 2
  newDepth rBYTE 2
  currentDepth rBYTE 2
  product rBYTE 2
ende

  org $200
  sei
  ldx #$ff                      ; Set the stack
  txs

  _setw IRQ, VBLANK_IRQ

  lda #$30                      ; Init `memory` to #$3000
  sta memory + 1
  lda #3
  tax
  lda #0
  sta memory
  tay

  cli

; $30-39 = 0-9
; $0a    = LF (\n)

Part1:
  GetNextChar:
  ldy #0
  lda ($00),y                   ; Load next character into accumulator
  beq ProgramComplete           ; If end of input, complete program
  inc memory                    ; Increment the memory pointer
  bne ContinueToNextChar        ; If pointer exceeds $ff,
  inc memory + 1                ;   Increment MSD
  ContinueToNextChar:
  cmp #$0a                      ; If newline,
  beq CheckDepth                ;   Check if new depth is greater than current
                                ; Else,
  jsr CompileNewDepth           ; Multiply newDepth * 10
  jmp GetNextChar               ; Continue to next character

Infinite:
  jmp Infinite
ProgramComplete:
  jmp ProgramComplete

CheckDepth:
  lda currentDepth              ; If currentDepth is 0,
  bne ContinueCheck
  lda currentDepth + 1
  beq SkipCheck                 ;   Skip check and set currentDepth to newDepth
                                ; Else,
  ContinueCheck:
  lda currentDepth
  sec
  sbc newDepth
  bcc IncCount
  bne SkipCheck
  lda currentDepth + 1
  sec
  sbc newDepth + 1
  bcc IncCount
  jmp SkipCheck

  IncCount:
  inc count + 1
  bne SkipCheck
  inc count

  SkipCheck:
  lda newDepth
  sta currentDepth
  lda newDepth + 1
  sta currentDepth + 1
  lda #0
  sta newDepth
  sta newDepth + 1
  jmp GetNextChar

CompileNewDepth:
  sec                           ; Set carry bit
  sbc #$30                      ; Get decimal value of char in accumulator
  pha                           ; Push number in accumulator onto the stack
  jsr MultiplyBy10              ; Multiply newDepth MSD by 10
  pla
  clc
  adc newDepth + 1
  bcc ContinueCND
  inc newDepth
  ContinueCND:
  sta newDepth + 1
  rts

MultiplyBy10:
  ; IN:  newDepth (number)
  ; OUT: none (updated `newDepth`)

  lda #0
  sta product + 1               ; Initialize product to 0
  sta product
  ldy #10                       ; Set iterator to 10
  lda newDepth
  beq AddNumLSD

  AddNumMSD:
  lda newDepth                  ; Put newDepth MSD in accumulator
  clc
  adc product                   ; Sum product and number in accumulator

  StoreNewProductMSD:
  sta product                   ; Store new sum in product MSD
  dey                           ; Decrement iterator
  bne AddNumMSD                 ; If iterator is not zero, goto AddNumMSD

  ldy #10                       ; Set iterator to 10

  AddNumLSD:
  lda newDepth + 1              ; Put newDepth LSD in accumulator
  clc
  adc product + 1               ; Sum product and number in accumulator
  bcc StoreNewProductLSD        ; If sum didnt exceed #$ff, StoreNewProductLSD
  inc product                   ; Else, increment product MSD

  StoreNewProductLSD:
  sta product + 1               ; Store new sum in product LSD
  dey                           ; Decrement iterator
  bne AddNumLSD                 ; If iterator is not zero, goto AddNumLSD

  lda product
  sta newDepth
  lda product + 1
  sta newDepth + 1              ; Store product in newDepth

  rts                           ; Return from subroutine


IRQ:
  rti

  org $3000
  ;incbin "roms/aoc2021/01/ins1.raw"
  incbin "roms/aoc2021/01/in.raw"
