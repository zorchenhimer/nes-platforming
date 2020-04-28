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

; Pixels per frame start jump speed
JMP_START_SPEED = 3
; Number of frames accelerating in a jump
JMP_FRAMES = 30
; Decay rate for each frame in a jump in fractions of a pixel (1/256)
JMP_RATE = 25

; Offsets for player horizontal collision
PLAYER_XOFFSET  = 3
PLAYER_YOFFSET  = 6

; Vertical offset for head collision
PLAYER_TOP      = 10

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

; Odd/Even tile row.  Used when drawing map.
OddEven: .res 1

; Player X and Y.  First byte is
; fraction, second is whole number.
PlayerX: .res 2
PlayerY: .res 2

; NMI check
Sleeping: .res 1

; This frame's controller input
Controller: .res 1
; Last frame's controller input
Controller_Old: .res 1

; Local variables for button
; pressed detection
btnX: .res 1
btnY: .res 1

; Is the player on the ground?
; 0 = no
; 1 = yes
IsGrounded: .res 1
IsJumping: .res 1
JumpFrame: .res 1
IsFalling: .res 1
LastGrounded: .res 1

; Current Jump acceleration per frame
JumpSpeed: .res 2

; Grace period after falling off ledge
; that you can still jump, in frames.
COYOTE = 5  ; # of frames
CoyoteCounter: .res 1

.segment "OAM"

SPRITE_X    = 3
SPRITE_Y    = 0
SPRITE_ATTR = 2
SPRITE_TILE = 1

; Player sprite is 2x2 tiles.
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

    ; Clear the attribute table to all $00
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

    ; Set the DataPointer to the
    ; start of the data.
    lda #<Blocks_FromTiled
    sta DataPointer
    lda #>Blocks_FromTiled
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
    lda #$00
    sta $2007
    sta $2007
    jmp @next

@ground:
    ; Even rows draw the top
    ; half of a block
    bit OddEven
    bmi @odd
    ; even
    lda #$02
    sta $2007
    lda #$03
    sta $2007
    jmp @next

@odd:
    ; Odd rows draw the bottom
    ; half of a block
    lda #$12
    sta $2007
    lda #$13
    sta $2007
    ;jmp @next

@next:
    iny
    cpy #16
    beq @nextRow
    jmp @col
@nextRow:
    ldy #0

    ; Filp/flop the flipflop
    lda OddEven
    eor #$FF
    sta OddEven
    and #$80
    bne @row

    ; Only update the data pointer when
    ; an even row is next.  Odd rows use
    ; the same data as the previous row.
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

    ; setup the player sprite tiles
    lda #$0E
    sta Player+(4*0)+SPRITE_TILE
    lda #$0F
    sta Player+(4*1)+SPRITE_TILE
    lda #$1E
    sta Player+(4*2)+SPRITE_TILE
    lda #$1F
    sta Player+(4*3)+SPRITE_TILE

    ; Set the initial X/Y for the player
    lda #40
    sta PlayerX+1
    sta PlayerY+1

Frame:
    ; Update the X/Y for each sprite
    ; in the player metasprite
    jsr UpdatePlayerSprite

    jsr ReadControllers
    lda #BUTTON_LEFT
    and Controller
    beq :+
    jsr Player_MoveLeft
:

    lda #BUTTON_RIGHT
    and Controller
    beq :+
    jsr Player_MoveRight
:

    lda IsJumping
    beq @noJump
    jsr Player_Jumping

    lda #BUTTON_A
    and Controller
    bne @jumpDone
    lda #0
    sta IsJumping
    sta JumpFrame
    sta IsFalling
    jmp @jumpDone

@noJump:
    lda CoyoteCounter
    beq :+
    dec CoyoteCounter
:

    lda IsGrounded
    sta LastGrounded
    jsr Player_Falling
    lda IsGrounded
    bne :+
    lda LastGrounded
    beq :+

    lda #COYOTE
    sta CoyoteCounter
:

    lda IsGrounded
    beq @checkCoyote
    jmp @justjump

@checkCoyote:
    ; Give a few frames of grace to jump after
    ; falling off a ledge
    lda CoyoteCounter
    beq @jumpDone

@justjump:
    lda #BUTTON_A
    jsr ButtonPressed
    beq @jumpDone

    lda #0
    sta IsGrounded
    sta JumpSpeed
    lda #JMP_FRAMES ; length of the jump
    sta IsJumping
    lda #JMP_START_SPEED
    sta JumpSpeed+1

@jumpDone:

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

; Player_MoveLeft and Player_MoveRight do the same
; thing but opposite each other.  First move the player
; on the X axis, then check to see if the player collides
; with a block.  If so, move the player back outside
; the block.
;
; Collision with two horizontal points:
; Left  = (PlayerX-PLAYER_XOFFSET, PlayerY-PLAYER_YOFFSET)
; Right = (PlayerX+PLAYER_XOFFSET, PlayerY-PLAYER_YOFFSET)
Player_MoveLeft:
    dec PlayerX+1

    lda PlayerY+1
    sec
    sbc #PLAYER_YOFFSET
    ; Divide by 16 for pixel coord -> block row
    lsr a
    lsr a
    lsr a
    lsr a
    tax
    lda Block_RowsLow, x
    sta DataPointer
    lda Block_RowsHi, x
    sta DataPointer+1

    lda PlayerX+1
    sec
    sbc #PLAYER_XOFFSET
    ; Divide by 16 for pixel coord -> block column
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    lda (DataPointer), y
    beq @done
    inc PlayerX+1
@done:
    rts

Player_MoveRight:
    inc PlayerX+1

    lda PlayerY+1
    sec
    sbc #PLAYER_YOFFSET
    ; Divide by 16 for pixel coord -> block row
    lsr a
    lsr a
    lsr a
    lsr a
    tax
    lda Block_RowsLow, x
    sta DataPointer
    lda Block_RowsHi, x
    sta DataPointer+1

    lda PlayerX+1
    clc
    adc #PLAYER_XOFFSET
    ; Divide by 16 for pixel coord -> block column
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    lda (DataPointer), y
    beq @done
    dec PlayerX+1
@done:
    rts

; Calculate jump acceleration and subtract it
; from the player's Y coordinate.  Increment
; the Jump frame for the next frame's calculation
; and check for collision with an above block.
; If the player collided with a block, move the
; player back down by adding JumpSpeed to the Y
; coordinate and resetting the jumping state.
Player_Jumping:
    ldx JumpFrame

    ; JumpSpeed = JumpSpeed - JMP_RATE
    lda JumpSpeed
    sec
    sbc #JMP_RATE
    sta JumpSpeed

    lda JumpSpeed+1
    sbc #0
    sta JumpSpeed+1

    ; PlayerY = PlayerY - JumpSpeed
    lda PlayerY
    sec
    sbc JumpSpeed
    sta PlayerY

    lda PlayerY+1
    sbc JumpSpeed+1
    sta PlayerY+1

    inc JumpFrame
    dec IsJumping
    bne @checkCollide

    ; Reset jump state if we have no more frames
    lda #0
    sta JumpFrame
    sta PlayerY
    sta JumpFrame

@checkCollide:
    ; Check for a collision in the same way we
    ; check the horizontal collision, only with
    ; different offsets.
    lda PlayerY+1
    sec
    sbc #PLAYER_TOP
    lsr a
    lsr a
    lsr a
    lsr a
    tax
    lda Block_RowsLow, x
    sta DataPointer
    lda Block_RowsHi, x
    sta DataPointer+1

    lda PlayerX+1
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    lda (DataPointer), y
    beq @done

    ; Player collided, move them back down and
    ; reset the jump state.
    lda PlayerY
    clc
    adc JumpSpeed
    sta PlayerY

    lda PlayerY+1
    adc JumpSpeed+1
    sta PlayerY+1
    lda #0
    sta IsJumping
    sta PlayerY ; Clear the fractional value
@done:
    rts

; Unlike jumping, falling is linear with a
; constant acceleration value.  Collision is
; calculated the same as elsewhere, but using
; no offsets from the Player's X/Y values.
Player_Falling:
    lda #0
    sta IsGrounded
    inc PlayerY+1
    inc PlayerY+1
    lda PlayerY+1
    lsr a
    lsr a
    lsr a
    lsr a
    tax
    lda Block_RowsLow, x
    sta DataPointer
    lda Block_RowsHi, x
    sta DataPointer+1
    lda PlayerX+1
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    lda (DataPointer), y
    beq @done
    ; Snap the player to the floor (top)
    ; of the brick they collided with and
    ; reset the grounded and jump states.
    txa
    asl a
    asl a
    asl a
    asl a
    sec
    sbc #2
    sta PlayerY+1
    lda #1
    sta IsGrounded
    lda #0
    sta PlayerY
    sta JumpFrame
@done:
    rts

; The Anchor point is on the bottom of the the sprite
; and centered
UpdatePlayerSprite:
    lda PlayerY+1
    sec
    sbc #15
    sta Player+(0*4)+SPRITE_Y
    sta Player+(1*4)+SPRITE_Y

    clc
    adc #8
    sta Player+(2*4)+SPRITE_Y
    sta Player+(3*4)+SPRITE_Y

    lda PlayerX+1
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
    lsr A          ; Bit0 -> Carry
    rol Controller ; Bit0 <- Carry
    dex
    bne @player1
    rts

; Was the given button pressed this frame?
; Input button in A.
ButtonPressed:
    sta btnX
    and Controller
    sta btnY

    lda Controller_Old
    and btnX

    cmp btnY
    bne @btnPress_stb

    ; no button change
    rts

@btnPress_stb:
    ; button released
    lda btnY
    bne @btnPress_stc
    rts

@btnPress_stc:
    ; button pressed
    lda #1
    rts

BG_Palette:
    .byte $0F, $00, $10, $20

SP_Palette:
    .byte $07, $17, $27, $37

.include "map-data.asm"
