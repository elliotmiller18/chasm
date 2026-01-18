REMINDER !!! RANK IS NUMBER FILE IS LETTER

# Functions:

- init board
args: board pointer

fills the board with pieces at the starting position 

- click
args: board pointer, rank, file

square := board pointer -> board[rank + (file * 8)]

deselect the last clicked square (a variable we have)
    i'm pretty sure that the fastest way to do this is set every single square to unallowed by anding every row (8 bytes) with 10111111 * 8. 
    this is only 8 instructions + a load and honestly i really don't think there's a more elegant way to do this in under 8 instructions

if the last clicked square is different from the square that was just clicked, we need to set it as clicked and mark the allowed squares as allowed. we do this by calling the allowed func.

if the last clicked square is NOT different (deselecting) we need to do nothing except write a sentinel value to the last clicked square

- allowed
args: board pointer, rank, file

this will branch to allowed functions for each piece type. each allowed function sets the allowed bit of all adjacent squares, i will write these bad boys later