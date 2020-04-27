; asmsyntax=ca65

; All blocks are 2x2 tiles
.enum BlockType
    Air
    Solid
.endenum

Block_RowsLow:
.repeat 15, row
    .byte .lobyte(Blocks_FromTiled + (16 * row))
.endrepeat

Block_RowsHi:
.repeat 15, row
    .byte .hibyte(Blocks_FromTiled + (16 * row))
.endrepeat

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

