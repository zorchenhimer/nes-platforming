; asmsyntax=ca65

.feature leading_dot_in_identifiers
.feature underline_in_numbers

.include "nes2header.inc"
nes2mapper 1
nes2prg 1 * 16 * 1024  ; 256k PRG
nes2chr 1 * 8 * 1024 ; 8k CHR
nes2mirror 'V'
nes2tv 'N'
nes2end

.segment "VECTORS"
    .word NMI
    .word RESET
    .word IRQ

.segment "TILES"

    .incbin "tiles.chr"

.segment "ZEROPAGE"
DataPointer: .res 2
OddEven: .res 1
RowCount: .res 1

.segment "OAM"

.segment "BSS"

.segment "PAGE0"

IRQ:
    rti

RESET:
    sei         ; Disable IRQs
    cld         ; Disable decimal mode

    ldx #$40
    stx $4017   ; Disable APU frame IRQ

    ldx #$FF
    txs         ; Setup new stack

    inx         ; Now X = 0

    stx $2000   ; disable NMI
    stx $2001   ; disable rendering
    stx $4010   ; disable DMC IRQs

:   ; First wait for VBlank to make sure PPU is ready.
    bit $2002   ; test this bit with ACC
    bpl :- ; Branch on result plus

:   ; Clear RAM
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x

    inx
    bne :-  ; loop if != 0

    bit $2002
    lda #$23
    sta $2006
    lda #$C0
    sta $2006

    ldx #32
    lda #0
:
    sta $2007
    sta $2007
    dex
    bne :-

    lda #<Blocks_FloorOnly
    sta DataPointer
    lda #>Blocks_FloorOnly
    sta DataPointer+1

    lda #$20
    sta $2006
    lda #$00
    sta $2006

    ldx #15
    lda #0
    sta OddEven
@row:
    ldy #0
@col:
    lda (DataPointer), y
    bne @ground
    ; Air
    lda #$0F
    sta $2007
    sta $2007
    jmp @next

@ground:
    bit OddEven
    bmi @odd
    ; even
    lda #$20
    sta $2007
    lda #$21
    sta $2007
    jmp @next

@odd:
    lda #$30
    sta $2007
    lda #$31
    sta $2007
    ;jmp @next

@next:
    iny
    cpy #16
    beq @nextRow
    jmp @col
@nextRow:
    ldy #0

    lda OddEven
    eor #$FF
    sta OddEven
    and #$80
    bne @row

    lda DataPointer
    clc
    adc #16
    sta DataPointer
    lda DataPointer+1
    adc #0
    sta DataPointer+1

    dex
    beq @done
    jmp @row
@done:

    lda #$80
    sta $2000   ; enable NMI
    lda #$1E
    sta $2001   ; enable sprites, bg, & 8px for both bg & sp

Frame:
    jmp Frame

NMI:
    bit $2002
    lda #$3F
    sta $2006
    lda #$00
    sta $2006

    ldx #0
:
    lda BG_Palette, x
    sta $2007
    inx
    cpx #4
    bne :-

    lda #$3F
    sta $2006
    lda #$11
    sta $2006
    ldx #0
:
    lda SP_Palette, x
    sta $2007
    inx
    cpx #4
    bne :-

    ; write sprites
    lda #$00
    sta $2003
    lda #$02
    sta $4014

    lda #$80
    sta $2000
    lda #0
    sta $2005
    sta $2005
    rti

BG_Palette:
    .byte $0F, $00, $10, $20

SP_Palette:
    .byte $0A, $1A, $2A, $3A

.include "map-data.asm"
