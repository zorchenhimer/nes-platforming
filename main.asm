; asmsyntax=ca65

.feature leading_dot_in_identifiers
.feature underline_in_numbers

; Button Constants
BUTTON_A        = 1 << 7
BUTTON_B        = 1 << 6
BUTTON_SELECT   = 1 << 5
BUTTON_START    = 1 << 4
BUTTON_UP       = 1 << 3
BUTTON_DOWN     = 1 << 2
BUTTON_LEFT     = 1 << 1
BUTTON_RIGHT    = 1 << 0

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

PlayerX: .res 1
PlayerY: .res 1

Sleeping: .res 1

Controller: .res 1
Controller_Old: .res 1

btnX: .res 1
btnY: .res 1

; Is the player on the ground?
; 0 = no
; 1 = yes
IsGrounded: .res 1
IsJumping: .res 1

.segment "OAM"

SPRITE_X    = 3
SPRITE_Y    = 0
SPRITE_ATTR = 2
SPRITE_TILE = 1

Player: .res 4*4

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

    ; setup the player sprite
    lda #$00
    sta Player+(4*0)+SPRITE_TILE
    lda #$01
    sta Player+(4*1)+SPRITE_TILE
    lda #$10
    sta Player+(4*2)+SPRITE_TILE
    lda #$11
    sta Player+(4*3)+SPRITE_TILE

    lda #50
    sta PlayerX
    sta PlayerY

Frame:
    jsr UpdatePlayerSprite

    jsr ReadControllers

    lda #BUTTON_LEFT
    and Controller
    beq :+
    dec PlayerX
:

    lda #BUTTON_RIGHT
    and Controller
    beq :+
    inc PlayerX
:

    lda IsJumping
    beq @noJump
    dec PlayerY
    dec PlayerY
    dec IsJumping

    lda #BUTTON_A
    and Controller
    bne @collideDone
    lda #0
    sta IsJumping
    jmp @collideDone

@noJump:

    jsr Player_Falling

    lda IsGrounded
    beq @collideDone
    ; only jump on the ground
    lda #BUTTON_A
    jsr ButtonPressed
    beq @collideDone

    lda #0
    sta IsGrounded
    lda #20 ; length of the jump
    sta IsJumping

@collideDone:

    lda #1
    sta Sleeping
:
    lda Sleeping
    bne :-
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

    sta Sleeping
    rti

Player_Falling:
    lda #0
    sta IsGrounded
    inc PlayerY
    inc PlayerY
    lda PlayerY
    lsr a
    lsr a
    lsr a
    lsr a
    tax
    lda Block_RowsLow, x
    sta DataPointer
    lda Block_RowsHi, x
    sta DataPointer+1
    lda PlayerX
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    lda (DataPointer), y
    beq @done
    txa
    asl a
    asl a
    asl a
    asl a
    sec
    sbc #2
    sta PlayerY
    lda #1
    sta IsGrounded
@done:
    rts

; The Anchor point is on the bottom of the the sprite
; and centered
UpdatePlayerSprite:
    lda PlayerY
    sec
    sbc #15
    sta Player+(0*4)+SPRITE_Y
    sta Player+(1*4)+SPRITE_Y

    clc
    adc #8
    sta Player+(2*4)+SPRITE_Y
    sta Player+(3*4)+SPRITE_Y

    lda PlayerX
    sec
    sbc #7
    sta Player+(0*4)+SPRITE_X
    sta Player+(2*4)+SPRITE_X

    clc
    adc #8
    sta Player+(1*4)+SPRITE_X
    sta Player+(3*4)+SPRITE_X
    rts

; Player input
ReadControllers:
    lda Controller
    sta Controller_Old

    ; Freeze input
    lda #1
    sta $4016
    lda #0
    sta $4016

    LDX #$08
@player1:
    lda $4016
    lsr A           ; Bit0 -> Carry
    rol Controller ; Bit0 <- Carry
    dex
    bne @player1
    rts

; Was a button pressed this frame?
ButtonPressed:
    sta btnX
    and Controller
    sta btnY

    lda Controller_Old
    and btnX

    cmp btnY
    bne btnPress_stb

    ; no button change
    rts

btnPress_stb:
    ; button released
    lda btnY
    bne btnPress_stc
    rts

btnPress_stc:
    ; button pressed
    lda #1
    rts

BG_Palette:
    .byte $0F, $00, $10, $20

SP_Palette:
    .byte $0A, $1A, $2A, $3A

.include "map-data.asm"
