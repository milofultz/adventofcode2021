include "64cube.inc"

enum $00                        ; Declare memory for variables
  memory rBYTE 2
  count rBYTE 2                 ; Amount of increases found
  newestPartial rBYTE 2          ; Current depth partial being input
  newDepth rBYTE 2              ; New sum of the last three depths
  currentDepth rBYTE 2          ; Last sum of the previous three depths
  newPartial rBYTE 2            ; The three depths for addition/subtraction
  midPartial rBYTE 2
  oldPartial rBYTE 2
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
  sta newestPartial
  sta newestPartial + 1
  sta newPartial
  sta newPartial + 1
  sta midPartial
  sta midPartial + 1
  sta oldPartial
  sta oldPartial + 1
  tay

  cli

; $30-39 = 0-9
; $0a    = LF (\n)

Part2:
  GetNextChar:
  ldy #0
  lda ($00),y                   ; Load next character into accumulator
  beq ProgramComplete           ; If end of input, complete program
  inc memory                    ; Increment the memory pointer
  bne ContinueToNextChar        ; If pointer exceeds $ff,
  inc memory + 1                ;   Increment MSD
  ContinueToNextChar:
  cmp #$0a                      ; If newline,
  beq CheckDepth                ;   Compile new composite depth and check if
                                ;   new depth is greater than current
                                ; Else,
  jsr CompileNewDepth           ; Multiply newestPartial * 10
  jmp GetNextChar               ; Continue to next character

Infinite:
  jmp Infinite
ProgramComplete:
  jmp ProgramComplete

CheckDepth:
  jsr CompileCompositeDepth

  lda currentDepth              ; If currentDepth is 0,
  bne ContinueCheck
  lda currentDepth + 1
  beq SkipCheck
  lda oldPartial                ; or if oldPartial is not yet set,
  bne ContinueCheck
  lda oldPartial + 1
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
  jsr PlaceDepthByAge
  lda newDepth
  sta currentDepth
  lda newDepth + 1
  sta currentDepth + 1
  jmp GetNextChar

CompileNewDepth:
  sec                           ; Set carry bit
  sbc #$30                      ; Get decimal value of char in accumulator
  pha                           ; Push number in accumulator onto the stack
  jsr MultiplyBy10              ; Multiply newestPartial MSD by 10
  pla
  clc
  adc newestPartial + 1
  sta newestPartial + 1
  bcc ContinueCND
  inc newestPartial
  ContinueCND:
  rts

CompileCompositeDepth:
  ; Add newest
  lda newestPartial + 1
  clc
  adc newDepth + 1
  sta newDepth + 1
  bcc SkipIncNdMSD
  inc newDepth
  SkipIncNdMSD:
  lda newestPartial
  clc
  adc newDepth
  sta newDepth
  ; Subtract oldest
  lda newDepth + 1
  sec
  sbc oldPartial + 1
  sta newDepth + 1
  bcs SkipDecNdMSD
  dec newDepth
  SkipDecNdMSD:
  lda newDepth
  sec
  sbc oldPartial
  sta newDepth

  rts

PlaceDepthByAge:
  ; Shift all partials over by one
  lda midPartial
  sta oldPartial
  lda midPartial + 1
  sta oldPartial + 1

  lda newPartial
  sta midPartial
  lda newPartial + 1
  sta midPartial + 1

  lda newestPartial
  sta newPartial
  lda newestPartial + 1
  sta newPartial + 1

  lda #0
  sta newestPartial
  sta newestPartial + 1

  rts



MultiplyBy10:
  ; IN:  newestPartial (number)
  ; OUT: none (updated `newestPartial`)

  lda #0
  sta product + 1               ; Initialize product to 0
  sta product
  ldy #10                       ; Set iterator to 10

  AddNumMSD:
  lda newestPartial             ; Put newestPartial MSD in accumulator
  clc
  adc product                   ; Sum product and number in accumulator

  StoreNewProductMSD:
  sta product                   ; Store new sum in product MSD
  dey                           ; Decrement iterator
  bne AddNumMSD                 ; If iterator is not zero, goto AddNumMSD

  ldy #10                       ; Set iterator to 10

  AddNumLSD:
  lda newestPartial + 1         ; Put newestPartial LSD in accumulator
  clc
  adc product + 1               ; Sum product and number in accumulator
  bcc StoreNewProductLSD        ; If sum didnt exceed #$ff, StoreNewProductLSD
  inc product                   ; Else, increment product MSD

  StoreNewProductLSD:
  sta product + 1               ; Store new sum in product LSD
  dey                           ; Decrement iterator
  bne AddNumLSD                 ; If iterator is not zero, goto AddNumLSD

  lda product
  sta newestPartial
  lda product + 1
  sta newestPartial + 1         ; Store product in newestPartial

  rts                           ; Return from subroutine


IRQ:
  rti

  org $3000
  ;incbin "roms/aoc2021/01/ins1.raw"
  ;incbin "roms/aoc2021/01/ins2.raw"
  incbin "roms/aoc2021/01/in.raw"
