.equ EMPTY, 0
.equ PAWN, 1
.equ KNIGHT, 2
.equ BISHOP, 3
.equ ROOK, 4
.equ QUEEN, 5
.equ KING, 6

.equ WHITE_TAG, 0x80

// args: x0 -> bitboard pointer (has 64 bytes of mem)
.global _init_board

_init_board:
    // zero-init the board (the middle portions will stay 0)
    stp xzr, xzr, [x0]
    stp xzr, xzr, [x0, #16]
    stp xzr, xzr, [x0, #32]
    stp xzr, xzr, [x0, #48]

    mov w10, #WHITE_TAG

    // load white pieces
    mov w9, #ROOK; 
    orr w9, w9, w10;
    strb w9, [x0, #0]
    strb w9, [x0, #7]

    mov w9, #KNIGHT
    orr w9, w9, w10
    strb w9, [x0, #1]
    strb w9, [x0, #6]

    mov w9, #BISHOP
    orr w9, w9, w10
    strb w9, [x0, #2]
    strb w9, [x0, #5]

    mov w9, #QUEEN
    orr w9, w9, w10
    strb w9, [x0, #3]

    mov w9, #KING
    orr w9, w9, w10
    strb w9, [x0, #4]

    mov w9, #PAWN
    orr w9, w9, w10
    mov x11, #8

    // fill in white pawns
    mov x9, #0x8181818181818181
    str x9, [x0, #8]

    // load black pieces
    mov w9, #ROOK
    strb w9, [x0, #56]
    strb w9, [x0, #63]

    mov w9, #KNIGHT
    strb w9, [x0, #57]
    strb w9, [x0, #62]

    mov w9, #BISHOP
    strb w9, [x0, #58]
    strb w9, [x0, #61]

    mov w9, #QUEEN
    strb w9, [x0, #59]

    mov w9, #KING
    strb w9, [x0, #60]

    // fill in black pawns
    mov x9, #0x0101010101010101
    str x9, [x0, #48]

    ret 

// we need a click function that will take a board pointer, rank, and file.
// this click function should check if 


