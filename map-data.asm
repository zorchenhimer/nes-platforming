; asmsyntax=ca65

; All blocks are 2x2 tiles
.enum BlockType
    Air
    Solid
.endenum

; Used for collisions
Blocks_FloorOnly:

.repeat 16
    .byte BlockType::Solid
.endrepeat

; 10 rows of air
.repeat 11
    .byte BlockType::Solid
    .repeat 14
        .byte BlockType::Air
    .endrepeat
    .byte BlockType::Solid
.endrepeat

; The rest is solid ground
.repeat 3
    .repeat 16
        .byte BlockType::Solid
    .endrepeat
.endrepeat
