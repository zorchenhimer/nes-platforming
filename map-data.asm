; asmsyntax=ca65

; Lookup tables that have values pointing to the
; start of each row of blocks in the data.
Block_RowsLow:
.repeat 15, row
    .byte .lobyte(Blocks_FromTiled + (16 * row))
.endrepeat

Block_RowsHi:
.repeat 15, row
    .byte .hibyte(Blocks_FromTiled + (16 * row))
.endrepeat

; Block metatiles.
; 0 = Air
; anythyng else = platform
Blocks_FromTiled:
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    .byte 2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2
    .byte 2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2
    .byte 2,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2
    .byte 2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2
    .byte 2,0,0,0,0,0,0,2,2,0,2,2,0,2,2,2
    .byte 2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2
    .byte 2,0,0,0,0,0,0,2,2,0,2,2,0,0,0,2
    .byte 2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2
    .byte 2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,2
    .byte 2,0,0,0,0,0,2,2,0,0,0,0,0,0,0,2
    .byte 2,2,2,0,0,0,0,0,2,2,0,0,0,0,0,2
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2

