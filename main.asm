.include "term.asm"
.include "syscall.asm"
.include "strings.asm"
.include "pong.asm"

.global _start

.section .data
game: .space 32
game_over_buff: .asciz "Game Over!"
somebuff: .space 32


.text
_start:
	bl term_clear_screen
	bl term_noncanon
	push {r0}
	ldr r6, game_address
	mov r0, r6
	add r1, r6, #4
	bl term_get_size

	GAME_GET_ROWS r0, r6
	GAME_GET_COLS r1, r6
	mov r4, #2
	sdiv r3, r0, r4
	GAME_SET_BALL_R r3, r6
	sdiv r3, r1, r4
	GAME_SET_BALL_C r3, r6 
	mov r3, #1
	GAME_SET_BALL_DIR_R r3, r6
	GAME_SET_BALL_DIR_C r3, r6

	sdiv r3, r0, r4		// rows / 2
	mov r7, #PLAYER_SIZE
	sdiv r5, r7, r4		// player_size / 2

	sub r3, r3, r5		// rows / 2 - player_size / 2
	GAME_SET_PLAYER1 r3, r6
	GAME_SET_PLAYER2 r3, r6


	mov r0, r6
	bl draw_game

	mov r0, r6
	GAME_GET_PLAYER1 r1, r6
	mov r2, #SIDE_LEFT
	bl draw_player

	mov r0, r6
	GAME_GET_PLAYER2 r1, r6
	mov r2, #SIDE_RIGHT
	bl draw_player
	
main_loop:
	mov r0, #100
	bl term_read_char
//	push {r0}
//	bl term_print_char2
//	pop {r0}
	cmp r0, #CHAR_X_L
	beq break
	cmp r0, #CHAR_Q_L
	beq player_left_up
	cmp r0, #CHAR_A_L
	beq player_left_down
	cmp r0, #CHAR_P_L
	beq player_right_up
	cmp r0, #CHAR_L_L
	beq player_right_down
	mov r0, r6
	bl move_ball
	cmp r0, #SIDE_LEFT
	beq game_over
	cmp r0, #SIDE_RIGHT
	beq game_over
	b main_loop

player_left_up:
	mov r0, r6
	mov r1, #SIDE_LEFT
	mov r2, #PLAYER_UP
	bl move_player
	b main_loop

player_left_down:
	mov r0, r6
	mov r1, #SIDE_LEFT
	mov r2, #PLAYER_DOWN
	bl move_player
	b main_loop

player_right_up:
	mov r0, r6
	mov r1, #SIDE_RIGHT
	mov r2, #PLAYER_UP
	bl move_player
	b main_loop

player_right_down:
	mov r0, r6
	mov r1, #SIDE_RIGHT
	mov r2, #PLAYER_DOWN
	bl move_player
	b main_loop

game_over:
	GAME_GET_ROWS r3, r6
	GAME_GET_COLS r4, r6

	mov r2, #2
	sdiv r0, r3, r2
	sdiv r1, r4, r2
	sub r1, r1, #2

	bl term_moveto

	
//	ldr r0, game_address
	mov r1, #10
//	bl term_print_known_string
	

break:
	pop {r0}
	bl term_canon
	mov r7, #SYS_EXIT
	mov r0, #52
	SYSCALL

game_address:
	.word game
somebuff_adr:
	.word somebuff

