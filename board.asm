.section __DATA,__data
.align 4

.global _selected_rank
.global _selected_file
// DO NOT SEPARATE
_selected_rank: .byte 0xFF
_selected_file: .byte 0xFF
// DO NOT SEPARATE

.section __TEXT,__text
.align 4

.equ EMPTY, 0
.equ PAWN, 1
.equ KNIGHT, 2
.equ BISHOP, 3
.equ ROOK, 4
.equ QUEEN, 5
.equ KING, 6

.equ WHITE_TAG, 0x80
.equ CLICKED_SENTINEL, 0xFFFF

.equ ALLOW_MASK, 0x40

// args: x0 -> bitboard pointer (has 64 bytes of mem)
.global _init_board
.global _click

_init_board:
    // zero-init the board (the middle portions will stay 0)
    stp xzr, xzr, [x0]
    stp xzr, xzr, [x0, #16]
    stp xzr, xzr, [x0, #32]
    stp xzr, xzr, [x0, #48]

    mov w10, #WHITE_TAG

    // load pieces (black, then white)
    mov w9, #ROOK;
    strb w9, [x0, #56]
    strb w9, [x0, #63]
    orr w9, w9, w10;
    strb w9, [x0, #0]
    strb w9, [x0, #7]

    mov w9, #KNIGHT
    strb w9, [x0, #57]
    strb w9, [x0, #62]
    orr w9, w9, w10
    strb w9, [x0, #1]
    strb w9, [x0, #6]

    mov w9, #BISHOP
    strb w9, [x0, #58]
    strb w9, [x0, #61]
    orr w9, w9, w10
    strb w9, [x0, #2]
    strb w9, [x0, #5]

    mov w9, #QUEEN
    strb w9, [x0, #59]
    orr w9, w9, w10
    strb w9, [x0, #3]

    mov w9, #KING
    strb w9, [x0, #60]
    orr w9, w9, w10
    strb w9, [x0, #4]

    // fill in white pawns
    mov x9, #0x8181818181818181
    str x9, [x0, #8]

    // fill in black pawns
    mov x9, #0x0101010101010101
    str x9, [x0, #48]

    ret 

// we need a click function that will take a board pointer, rank, and file.
// this click function should check if 

//args x0: board pointer x1: rank (0-indexed, uint8_t) x2: file (letters 0-indexed, uint8_t)
_click:

    mov w9, #ALLOW_MASK
    // broadcast disallow mask into vector register
    dup v0.16b, w9

    // load the full board into vector register
    ld1 {v1.16b, v2.16b, v3.16b, v4.16b}, [x0]

    // apply the mask to the full board (disallowing every square)
    // aka clear bit 6
    bic v1.16b, v1.16b, v0.16b
    bic v2.16b, v2.16b, v0.16b
    bic v3.16b, v3.16b, v0.16b
    bic v4.16b, v4.16b, v0.16b

    // store the full board
    st1 {v1.16b, v2.16b, v3.16b, v4.16b}, [x0]

    // get last clicked rank + file in a single register (w9)
    adrp x10, _selected_rank@GOTPAGE
    ldr x10, [x10, _selected_rank@GOTPAGEOFF]
    ldrh w9, [x10]
    // combine rank + file passed in so they're in the same form
    // as our memory (arm is little endian)
    orr  w1, w1, w2, lsl #8     
    // we dgaf about the upper 48 bits of x1
    cmp w9, w1
    b.ne _clicking_different

    // store sentinel value for last clicked rank + file
    mov w14, #CLICKED_SENTINEL
    strh w14, [x10]

    ret

_clicking_different:
    // store the position that was just clicked as currently clicked
    strb w1, [x10]
    strb w2, [x10, #1]

    //TODO: finish me
    ret