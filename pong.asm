.arm
// This file contains the game logic of pong

/* TODO revise some of the boundary stuff + 
 * move_ball label has some redundancy at the player collisions
 * */

.ifndef PONG_ASM
.equ	PONG_ASM,	0x0

.include "term.asm"

.section .rodata
hashtag_buff:	.asciz "#"
space_buff:	.asciz " "
x_buff:		.asciz "x"
asterisk_buff:	.asciz "*"

char_space_adr:
	.word space_buff
char_hashtag_adr:
	.word hashtag_buff
char_x_adr:
	.word x_buff
char_asterisk_adr:
	.word asterisk_buff

.global move_ball
.global draw_player
.global draw_game
.global move_player

.equ LEFT_WALL_BOUND,	2

.equ PLAYER_SIZE,	5
.equ PLAYER_UP,		-1
.equ PLAYER_DOWN,	1
.equ SIDE_LEFT,		-1
.equ SIDE_RIGHT,	1
.equ SIDE_NONE,		0

.equ CHAR_SPACE,	32
.equ CHAR_ASTERISK,	42
.equ CHAR_HASHTAG,	35
.equ CHAR_X,		88

.equ CHAR_X_L,		120
.equ CHAR_Q_L,		113
.equ CHAR_A_L,		97
.equ CHAR_P_L,		112
.equ CHAR_L_L,		108

.equ DEBUG,		0x0

/* 32 bytes */
/* struct Game{
 *	int rows;
 *	int cols;
 *
 *	int ball_r;
 *	int ball_c;
 *
 *	int ball_dir_r;
 *	int ball_dir_c;
 *
 *	int player1;
 *	int player2;
 * }
 * */

/* getters and setters for the game structure
 * assumes the 32 byte game structure
 * */
.macro GAME_GET_ROWS register, mem
	ldr \register, [\mem]
.endm /* GAME_GET_ROWS */

.macro GAME_GET_COLS register, mem
	ldr \register, [\mem, #4]
.endm /* GAME_GET_COLS */

.macro GAME_GET_BALL_R register, mem
	ldr \register, [\mem, #8]
.endm /* GAME_GET_BALL_R */

.macro GAME_GET_BALL_C register, mem
	ldr \register, [\mem, #12]
.endm /* GAME_GET_BALL_C */

.macro GAME_GET_BALL_DIR_R register, mem
	ldr \register, [\mem, #16]
.endm /* GAME_GET_BALL_DIR_R */

.macro GAME_GET_BALL_DIR_C register, mem
	ldr \register, [\mem, #20]
.endm /* GAME_GET_BALL_DIR_C */

.macro GAME_GET_PLAYER1 register, mem
	ldr \register, [\mem, #24]
.endm /* GAME_GET_PLAYER1 */

.macro GAME_GET_PLAYER2 register, mem
	ldr \register, [\mem, #28]
.endm /* GAME_GET_PLAYER2 */

// for setters we just reverse order
.macro GAME_SET_ROWS register, mem
	str \register, [\mem]
.endm /* GAME_SET_ROWS */

.macro GAME_SET_COLS register, mem
	str \register, [\mem, #4]
.endm /* GAME_SET_COLS */

.macro GAME_SET_BALL_R register, mem
	str \register, [\mem, #8]
.endm /* GAME_SET_BALL_R */

.macro GAME_SET_BALL_C register, mem
	str \register, [\mem, #12]
.endm /* GAME_SET_BALL_C */

.macro GAME_SET_BALL_DIR_R register, mem
	str \register, [\mem, #16]
.endm /* GAME_SET_BALL_DIR_R */

.macro GAME_SET_BALL_DIR_C register, mem
	str \register, [\mem, #20]
.endm /* GAME_SET_BALL_DIR_C */

.macro GAME_SET_PLAYER1 register, mem
	str \register, [\mem, #24]
.endm /* GAME_SET_PLAYER1 */

.macro GAME_SET_PLAYER2 register, mem
	str \register, [\mem, #28]
.endm /* GAME_SET_PLAYER2 */

/* not very efficient but these are used in debug mode anyway,
 * we're saving all register onto the stack
 * */

/* Calls the given function in fun with the value val
 * FUNCALL_N, where N represents number of parameters
 * given to the function called
 * */
.macro FUNCALL_1 val, fun
	push {r0,r1,r2,r3}
	mov r0, \val
	bl \fun
	pop {r0,r1,r2,r3}
.endm /* FUNCALL_1 */

.macro FUNCALL_2 val, val2, fun
	push {r0,r1,r2,r3}
	mov r0, \val
	mov r1, \val2
	bl \fun
	pop {r0,r1,r2,r3}
.endm /* FUNCALL_2 */

.macro FUNCALL_3 val, val2, val3, fun
	push {r0,r1,r2,r3}
	mov r0, \val
	mov r1, \val2
	mov r2, \val3
	bl \fun
	pop {r0,r1,r2,r3}
.endm /* FUNCALL_3 */

.macro FUNCALL_4 val, val2, val3, val4, fun
	push {r0,r1,r2,r3}
	mov r0, \val
	mov r1, \val2
	mov r2, \val3
	mov r3, \val4
	bl \fun
	pop {r0,r1,r2,r3}
.endm /* FUNCALL_4 */


/* Moves the ball to the corresponding position in terminal
 * and determines if any player won/lost.
 * @Game *game: game pointer to get data from
 * @returns -> int: values which determine whether someone won
 * int move_ball(Game *game)
 * */
move_ball:
	push {r4, r5, fp, lr}

// prints out all game data at the top of the terminal
.ifdef DEBUG
	mov r2, r0

	FUNCALL_2 #2, #20, term_moveto
	GAME_GET_ROWS r1, r2	
	FUNCALL_1 r1, term_print_int
	
	FUNCALL_2 #3, #20, term_moveto	
	GAME_GET_COLS r1, r2
	FUNCALL_1 r1, term_print_int
	
	FUNCALL_2 #4, #20, term_moveto
	GAME_GET_BALL_R r1, r2
	FUNCALL_1 r1, term_print_int
	
	FUNCALL_2 #5, #20, term_moveto
	GAME_GET_BALL_C r1, r0
	FUNCALL_1 r1, term_print_int

	FUNCALL_2 #6, #20, term_moveto
	GAME_GET_PLAYER1 r1, r0
	FUNCALL_1 r1, term_print_int
	
	FUNCALL_2 #7, #20, term_moveto
	GAME_GET_PLAYER2 r1, r0
	FUNCALL_1 r1, term_print_int

	mov r0, r2
.endif /* DEBUG */

	GAME_GET_BALL_R r1, r0
	GAME_GET_BALL_C r2, r0
	push {r0,r1,r2}
	mov r0, r1
	mov r1, r2
	bl term_moveto
	pop {r0, r1, r2}

	ldr r2, char_space_adr	// term_print_char(' ')
	push {r0}		// preserve game state
	mov r0, r2
	bl term_print_char
	pop {r0}		// game game state back

	GAME_GET_BALL_R r1, r0
	GAME_GET_BALL_C r2, r0
	GAME_GET_BALL_DIR_R r3, r0
	GAME_GET_BALL_DIR_C r4, r0
	
	add r1, r1, r3			// ball_r += ball_dir_r
	add r2,	r2, r4			// ball_c += ball_dir_c
//	push {r0, r1, r2, r3}
//	mov r0, r1
//	bl term_print_int
//	pop {r0, r1, r2, r3}
//	push {r0, r1, r2, r3}
//	mov r0, r2
//	bl term_print_int
//	pop {r0, r1, r2, r3}
	
	GAME_SET_BALL_R r1, r0
	GAME_SET_BALL_C r2, r0
	push {r0, r1, r2}		// save game, ball_r, ball_c
	mov r0, r1
	mov r1, r2
	bl term_moveto			// term_moveto(ball_r, ball_c)
	
	ldr r0, char_asterisk_adr
	bl term_print_char

	pop {r0, r1, r2}		// get ball_r, ball_r back
	GAME_GET_ROWS r3, r0
	
	cmp r1, #2			// ball_r == 2 ?
	beq move_ball_change_dir_hor
	sub r4, r3, #3			// rows - 3
	cmp r1, r4			// ball_r == rows - 3 ?
	bne move_ball_ver

// NOTE try with OR and invert it
move_ball_change_dir_hor:
	GAME_GET_BALL_DIR_R r3, r0
	mov r4, #-1			// ball_dir_r * -1
	mul r5, r3, r4
	GAME_SET_BALL_DIR_R r5, r0	// game->ball_dir_r = -ball_dir_r

move_ball_ver:
	cmp r2, #3			// ball_c == 3 ?
	bne move_ball_ver_other

/* we test for player1 collision */
move_ball_ver_and:
	GAME_GET_PLAYER1 r4, r0

	/* if its lower then its safe
	 * otherwise check for the collision */

	cmp r1, r4			// ball_r >= player1?
	blt move_ball_ver_other		// skip to next next condition if not true

/* gets here if its equal or bigger than player row position */
move_ball_ver_and2:
	add r4, r4, #PLAYER_SIZE
	cmp r1, r4			// ball_r < player1 + PLAYER_SIZE
	bge move_ball_wall_bound	// go to next condition if not true
	GAME_GET_BALL_DIR_C r3, r0	// r3 = game->ball_dir_c
	mov r4, #-1			// for inversing the direction
	mul r5, r3, r4			// inverse direction
	GAME_SET_BALL_DIR_C r5, r0	// set the inversed direction

/* the second side checking */
move_ball_ver_other:
	GAME_GET_COLS r3, r0

	/* this needs to be 
	 * done because of alignement issues
	 * */
	push {r0,r1,r2,r3}
	mov r0, r2
	bl term_print_char
	pop {r0,r1,r2,r3}

	sub r3, r3, #4			// bounds
	cmp r2, r3			// compare game cols and ballc
	bne move_ball_wall_bound

/* check for player2 collision */
move_ball_ver_other_and:
	GAME_GET_PLAYER2 r3, r0		// get row start form player2
	cmp r1, r3			// compare ball_r against player row start
	blt move_ball_wall_bound

/* there could be player2 collision so check for it */
move_ball_ver_other_and2:
	add r3, r3, #PLAYER_SIZE
	cmp r1, r3			// compare ball_r against player size
	bge move_ball_wall_bound
	
	GAME_GET_BALL_DIR_C r3, r0	// direction
	mov r4, #-1			// for inverse
	mul r5, r3, r4			// inverse the direction
	GAME_SET_BALL_DIR_C r5, r0	// save it

/* check for left wall collision*/
move_ball_wall_bound:
	cmp r2, #LEFT_WALL_BOUND
	bne move_ball_wall_bound2	// if its not jump to right wall bound
	GAME_GET_BALL_DIR_C r3,r0
	mov r4, #-1			// prepare for inverse
	mul r5, r3, r4			// inverse
	GAME_SET_BALL_DIR_C r5,r0	// save the inverse

/* right wall bound */
move_ball_wall_bound2:
	GAME_GET_COLS r3, r0
	sub r3,r3, #3

//	push {r0, r1, r2, r3}
//	mov r0, r3
//	bl term_print_int
//	pop {r0, r1, r2, r3}
	cmp r2, r3			// if it is prepare for inverse
	bne move_ball_side_left
	GAME_GET_BALL_DIR_C r3, r0
	mov r4, #-1
	mul r5, r3, r4			// inverse
	GAME_SET_BALL_DIR_C r5, r0	// save the inverse
		
/* left side won */
move_ball_side_left:
	cmp r2, #2
	moveq r0, #SIDE_LEFT
	beq move_ball_end

/* right side won */
move_ball_side_right:
	GAME_GET_COLS r3, r0
	sub r3, r3, #3
	cmp r2, r3
	moveq r0, #SIDE_RIGHT
	beq move_ball_end
	

move_ball_side_none:
	mov r0, #SIDE_NONE

move_ball_end:
	pop {r4, r5, fp, lr}
	bx lr

/* Draws a player given the position and side,
 * which determines player 1/2.
 * @Game *game: game data
 * @int position: position of player
 * @int side: side of player
 * void draw_player(Game *game, int position, int side) */
draw_player:	
	push {r4, r5, fp, lr}
	cmp r2, #SIDE_LEFT
	bne draw_player_column_ne
	
draw_player_column_eq:
	mov r2, #2			// column
	b draw_player_pre_loop

draw_player_column_ne:
	GAME_GET_COLS r2, r0
	sub r2, r2, #3

draw_player_pre_loop:
	mov r4, #0			// counter
	mov r5, #PLAYER_SIZE		// boundary check against the counter

draw_player_loop:
	cmp r4, r5
	beq draw_player_end
	push {r1, r2}			// save position and column info
	add r0, r1, r4			// position + i
//	push {r0, r1, r2 , r3}
//	bl term_print_int
//	pop {r0, r1, r2 , r3}
	mov r1, r2			// term_moveto(position+i, column)
	bl term_moveto
	ldr r0, char_x_adr
	bl term_print_char
	pop {r1, r2}
	add r4, r4, #1
	b draw_player_loop
	
draw_player_end:
	pop {r4, r5, fp ,lr}
	bx lr

/* Draws the game (borders, decoration).
 * @Game *game: game data
 * void draw_game(Game *game)
 * */
draw_game:
	push {r4, r5, fp, lr}
	mov r4, #0			//counter
	GAME_GET_COLS r5, r0		// r5 = game->cols

draw_game_loop_cols:
	cmp r4, r5			// compare counter to cols
	beq draw_game_pre_loop_rows
	push {r0}			// save game state
	mov r0, #0			// term_moveto(0, i(r4 counter))
	mov r1, r4			// r1 = cols 
	bl term_moveto			// term_moveto(0, cols)

	ldr r0, char_hashtag_adr	// get address of literal cstring constant of #
	bl term_print_char		// print it out
	pop {r0}			// get back the game state

	GAME_GET_ROWS r1, r0
	push {r0}
	mov r0, r1
	sub r0, r0, #1			// rows - 1
	mov r1, r4			// termmoveto(rows - 1, i(r4 counter))
	bl term_moveto

	ldr r0, char_hashtag_adr
	bl term_print_char
	pop {r0}
	add r4, r4, #1			// inc counter
	b draw_game_loop_cols

draw_game_pre_loop_rows:
	mov r4, #0			//counter
	GAME_GET_ROWS r5, r0

draw_game_loop_rows:
	cmp r4, r5			// counter == rows
	beq draw_game_end
	push {r0}
	mov r0, r4			// term_moveto(i(r4 counter), 0)
	mov r1, #0 
	bl term_moveto

	ldr r0, char_hashtag_adr
	bl term_print_char

	pop {r0}
	GAME_GET_COLS r1, r0
	push {r0}
	sub r1,r1, #1			// rows - 1
	mov r0, r4			// termmoveto(rows - 1, i(r4 counter))
	bl term_moveto

	ldr r0, char_hashtag_adr
	bl term_print_char
	pop {r0}
	add r4, r4, #1			// inc counter
	b draw_game_loop_rows

draw_game_end:
	pop {r4, r5, fp, lr}
	bx lr

/* Moves player to given terminal coordinates.
 * @Game *game: game data
 * @int side: side of player to move
 * @int dir: direction to which move to (up down)
 * void move_player(Game *game, int side, int dir)
 * */
move_player:
	push {r4, r5, r6, r7, fp, lr}
	cmp r1, #SIDE_LEFT
	beq move_player_col_eq
	GAME_GET_COLS r4, r0		// column
	sub r4, r4, #3
	mov r3, r0

	/* we avoid some additional jumps thanks to this */

	add r3, r3,  #28		// &player2
	mov r5, r3			// player = &player2
	b move_player_dir_up

move_player_col_eq:
	mov r4, #2			// left boundary
	mov r3, r0

	/* avoid additional jumps */
	add r3, r3, #24
	mov r5, r3			// player = &player1

move_player_dir_up:
	cmp r2, #PLAYER_UP
	bne move_player_dir_down
	ldr r3, [r5]			// value of player

	/* NOTE probably should have some sort of
	 * constant to determine the bottom boundary
	 * */
	cmp r3, #2
	ble move_player_end
	
	/* we dont need the game pointer after this */

	push {r3}			// save the player value
	add r0, r3, #PLAYER_SIZE	// r0 = player + PLAYER_SIZE
	sub r0, r0, #1			// --r0
	mov r1, r4			// col position
	bl term_moveto			// term_moveto(player + 
					// PLAYER_SIZE - 1, column)
	ldr r0, char_space_adr
	bl term_print_char
	pop {r3}

	sub r3, #1
	str r3, [r5]			// set the player value 
	mov r0, r3			// player value par1
	mov r1, r4			// col value par2
	bl term_moveto
	ldr r0, char_x_adr
	bl term_print_char
	b move_player_end


move_player_dir_down:
	ldr r7, [r5]			// value of player
//	push {r3}			// save the player value
	GAME_GET_ROWS r6, r0		// r6 = rows
	sub r6, r6, #1			// r6--
	add r0, r7, #PLAYER_SIZE	// player + PLAYER_SIZE
//	push {r0, r1, r2, r3}
//	bl term_print_int
//	pop {r0, r1, r2, r3}
	cmp r0, r6			// player + PLAYER_SIZE == rows - 1 ? 
	bge move_player_end
//	add r3, r3, #1			// player + PLAYER_SIZE + 1
	mov r0, r7
	mov r1, r4
	bl term_moveto			// term_moveto(player, column)
	ldr r0, char_space_adr
	bl term_print_char
//	pop {r3}

	add r7, r7, #1			// write the player value 
					// to the field of the game struct
	str r7, [r5]
	
	add r7, r7, #PLAYER_SIZE	// player + PLAYERSIZE - 1
	add r7, #-1
	mov r0, r7			// player value par1
	mov r1, r4			// col value par2
	bl term_moveto
	ldr r0, char_x_adr
	bl term_print_char
	
move_player_end:
	pop {r4, r5, r6, r7, fp, lr}
	bx lr
	
.endif	/* PONG_ASM */
