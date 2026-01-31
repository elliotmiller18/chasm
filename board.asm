.section __DATA,__data
.align 4

.global _selected_rank
.global _selected_file
// DO NOT SEPARATE
_selected_rank: .byte 0xFF
_selected_file: .byte 0xFF
// DO NOT SEPARATE
// we're going to toggle this between WHITE_TAG and 0 for quick
// checks on clicked peices
_white_to_play: .byte WHITE_TO_PLAY_INIT

.section __TEXT,__text
.align 4

.equ EMPTY, 0
.equ PAWN, 1
.equ TEMP_WHITE_PAWN, 0x81
.equ KNIGHT, 2
.equ BISHOP, 3
.equ ROOK, 4
.equ QUEEN, 5
.equ KING, 6

//[color][allowed][data1][data2][empty][piece bit 2][piece bit 1][piece bit 0]
.equ WHITE_TAG, 0x80
.equ WHITE_TAG_BIT, 7
.equ CLICKED_SENTINEL, 0xFFFF

.equ ALLOW_MASK, 0x40
.equ WHITE_TO_PLAY_INIT, 0x01

.equ EN_PASSANTABLE_PAWN, 0x21

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

//args x0: board pointer x1: rank (numbers 0-indexed, uint8_t) x2: file (letters 0-indexed, uint8_t)
_click:
    // get index by doing rank * 8 and then adding the file
    add w9, w2, w1, lsl #3

    // get previously selected rank and file into w10 and w11 respectively
    adrp x15, _selected_rank@GOTPAGE
    ldr x15, [x15, _selected_rank@GOTPAGEOFF]
    ldrb w10, [x15]
    ldrb w11, [x15, #1]

    // get previously selected index in the same way 
    add w12, w11, w10, lsl #3
    
    // if the old and new indices are the same, we want to deselect (clicking the same square twice deselects)
    // otherwise we check if the player is trying to move a piece (eg they just selected an allowed square)
    // and if they are move the piece that was previously clicked there, if they didnt click an allowed square
    // we just select that

    // deselect
    mov x14, CLICKED_SENTINEL
    strh w14, [x15]
    // if the two indices are the same, skip selecting the new index
    cmp w9, w12
    b.eq _clear_allowed

    // get clicked square and check if a move there is allowed
    ldrb w13, [x0, x9]
    tst w13, #ALLOW_MASK
    // if we can't move there we want to set previously selected and NOT move any pieces
    b.eq _set_previously_selected

    // grab turn bit into x12
    adrp x11, _white_to_play@GOTPAGE
    ldr x11, [x11, _white_to_play@GOTPAGEOFF]
    ldrb w13, [x11]

    // flip and store turn bit
    eor w13, w13, WHITE_TO_PLAY_INIT
    strb w13, [x11]

    // get previously selected piece
    ldrb w13, [x0, x12]
    // store previously selected piece in currently selected square
    strb w13, [x0, x9]
    // empty the old square 
    mov x13, EMPTY
    strb w13, [x0, x12]
    //HACK: move dummy, identical values into w9 and w12 so that clear_allowed ALWAYS returns
    mov x9, xzr
    mov x12, xzr
    b _clear_allowed

_set_previously_selected:
    // store rank + file
    strb w1, [x15]
    strb w2, [x15, #1]

_clear_allowed:
    // broadcast allow mask into vector register
    mov w14, #ALLOW_MASK
    dup v0.16b, w14

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

    // compare previously and currently selected indexes
    cmp w9, w12
    b.ne _clicking_different

    ret

_clicking_different:
    //TODO: finish me with all pieces
    // load just clicked piece
    ldrb w10, [x0, x9]
    // load white_to_play bit
    adrp x11, _white_to_play@GOTPAGE
    ldr x11, [x11, _white_to_play@GOTPAGEOFF]
    ldrb w12, [x11]
    // shift the piece WHITE_TAG_BIT to the right to just get the color tag bit
    lsr w13, w10, WHITE_TAG_BIT
    cmp w13, w12

    b.eq _valid_turn
    ret

_valid_turn:
    
    cmp w10, #TEMP_WHITE_PAWN
    b.eq _validate_pawn

    ret 


// Piece Validators
_validate_pawn:
    // gonna do white first and then figure out how to generalize
    
    //TODO: this doesnt work for some reason
    
    // index above the pawn, we'll never have to worry about this overflowing because a pawn on the
    // last row simply becomes another piece
    add w11, w9, #8
    // get the piece above the pawn, if it's empty allow it
    ldrb w12, [x0, x11]
    cmp w12, #EMPTY
    
    b.ne _skip_double_checks

    // store an empty that's allowed here, this works with black or white
    mov w13, #ALLOW_MASK
    strb w13, [x0, x11]

    // check if we're on rank 2 for double move
    cmp w1, #1
    b.ne _skip_double_checks

    add w15, w11, #8
    // get the piece two above the pawn (x11 is already above)
    ldrb w12, [x0, x15]
    mov w13, #ALLOW_MASK
    cmp w12, #EMPTY
    // because empty is just 0s the allowed flag is 
    csel w12, w13, w12, eq
    strb w12, [x0, x15]

_skip_double_checks:

    sub w15, w11, #1
    cmp w2, #0
    b.eq _skip_left_checks

    // up and to the left
    ldrb w12, [x0, x15]
    cmp w12, #EMPTY
    b.eq _skip_left_checks

    orr w13, w12, #ALLOW_MASK
    tst w12, #WHITE_TAG

    csel w12, w13, w12, eq
    strb w12, [x0, x15]

    // TODO: en passant
        // directly to the left, just for en passant 
        // sub w14, w9, #1
        // ldrb w12, [x0, x9]
        // mov w13, #EN_PASSANTABLE_PAWN
        // tst w12, w13

_skip_left_checks:

    // note: this is just the left check logic except we add instead of sub

    // if we're on the 8th rank skip right check
    cmp w2, #7
    b.eq _skip_right_checks

    add w15, w11, #1

    // up and to the right
    ldrb w12, [x0, x15]
    cmp w12, #EMPTY
    b.eq _skip_right_checks

    orr w13, w12, #ALLOW_MASK
    tst w12, #WHITE_TAG

    csel w12, w13, w12, eq
    strb w12, [x0, x15]

    //TODO: en passant

_skip_right_checks:

    ret
