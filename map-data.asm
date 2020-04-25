; asmsyntax=ca65

; All blocks are 2x2 tiles
.enum BlockType
    Air
    Solid
.endenum

Block_RowsLow:
.repeat 15, row
    .byte .lobyte(Blocks_FloorOnly + (16 * row))
.endrepeat

Block_RowsHi:
.repeat 15, row
    .byte .hibyte(Blocks_FloorOnly + (16 * row))
.endrepeat

; Used for collisions
Blocks_FloorOnly:

.repeat 16
    .byte BlockType::Solid
.endrepeat

; 10 rows of air
.repeat 10
    .byte BlockType::Solid
    .repeat 14
        .byte BlockType::Air
    .endrepeat
    .byte BlockType::Solid
.endrepeat

.byte BlockType::Solid
.byte BlockType::Solid
.repeat 13
    .byte BlockType::Air
.endrepeat
.byte BlockType::Solid

; The rest is solid ground
.repeat 3
    .repeat 16
        .byte BlockType::Solid
    .endrepeat
.endrepeat
