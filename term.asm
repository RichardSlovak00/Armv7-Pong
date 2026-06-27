.arm
/* this file contains all necessary functions to work with the terminal to
 * to create the pong game in 32bit ARM assembly */
.ifndef TERM_ASM
.set 	TERM_ASM, 1



.include "strings.asm"
.include "a_outformat.asm"
.include "syscall.asm"

.global term_screen_clear
.global term_print_string
.global term_print_known_string
.global term_get_size
.global term_print_int
.global term_noncanon
.global term_canon
.global term_read_char
.global term_moveto

.equ	TCGETS,		0x5401
.equ	TCSETS,		0x5402
.equ	TIOCGWINSZ,	0x5413
.equ	ISIG,		0x0001

.equ 	POLLIN,		0x0001
.equ 	POLLPRI,	0x0002
.equ 	POLLOUT,	0x0004

.equ	CHAR_X_NUM,	0x0078
.equ	CHAR_N_NUM,	0x006E
.equ	NULL_TERM,	0x0000

/* we need this to have unique 
 * addresses when expanding the macro
 * */
.equ	N_CLEAR_SCREEN,		0x0000
.equ	N_RESET_ALL,		0x0001
.equ	N_COLOR_RED,		0x0002
.equ	N_COLOR_BLUE,		0x0003
.equ	N_BACKGROUND_RED,	0x0004
.equ	N_BACKGROUND_BLUE,	0x0005
.equ	N_STYLE_BLINK,		0x0006
.equ	N_STYLE_BLIND_RAPID,	0x0007

.equ	TERM_VLAG_FG_COLOR_SECTOR_POS,	0x0000
.equ	TERM_VLAG_BG_COLOR_SECTOR_POS,	0x0003
.equ	TERM_VLAG_OTHER_SECTOR_POS,	0x0006

.equ	TERM_VLAG_FG_COLOR_SECTOR_LEN,	0x0003
.equ	TERM_VLAG_BG_COLOR_SECTOR_LEN,	0x0003
.equ	TERM_VLAG_OTHER_SECTOR_LEN,	0x0003

.equ	TERM_VLAG_FG_COLOR_NONE,	0x0000
.equ	TERM_VLAG_FG_COLOR_RED,		0x0001
.equ	TERM_VLAG_FG_COLOR_BLUE,	0x0002
.equ	TERM_VLAG_FG_COLOR_GREEN,	0x0004
.equ	TERM_VLAG_BG_COLOR_RED,		0x0008
.equ	TERM_VLAG_BG_COLOR_BLUE,	0x0010
.equ	TERM_VLAG_BG_COLOR_GREEN,	0x0020
.equ	TERM_VLAG_BLINK,		0x0040

.macro TERM_VFLAG_SECTOR_MASK flag, save, name
	mov \save, #1, lsl \name_LEN
	sub \save, \save, #1
	lsl \save, \save, \name_SECTOR_POS
	and \save, \flag, \save
.endm /* TERM_VLAG_FG_COLOR_SECOND_MASK */

/* NOTE: doesnt work for all formats (moveto) */

/* prints out given format */
.macro TERM_FORMAT_PRINT format, num
	push {r7}
	mov r7, #SYS_WRITE	// all prep for the syscall
	mov r0, #STDOUT_FILENO

	/* hacky solution*/
	ldr r1, addr\num

	mov r2, #\format\()_LEN
	SYSCALL
	pop {r7}
	bx lr
addr\num: .word \format		// hacky	
.endm	/* TERM_FORMAT_PRINT */

.section .rodata
num:		.ascii 	"0"
moveto_code:	.asciz	"\x1b[n;nH"
moveto_code_end:
.equ 	moveto_code_len,	moveto_code_end - moveto_code

.text

/* Clears the terminal screen.
 * void term_screen_clear()
 * */
term_clear_screen:
	TERM_FORMAT_PRINT A_OUTFORMAT_CLEAR_SCREEN, N_CLEAR_SCREEN

/* Resets everything in the terminal.
 * void term_reset_all()
 * */
term_reset_all:
	TERM_FORMAT_PRINT A_OUTFORMAT_RESET_ALL, N_RESET_ALL

/* Foreground red color in the terminal.
 * void term_color_red()
 * */
term_color_red:
	TERM_FORMAT_PRINT A_OUTFORMAT_COLOR_RED, N_COLOR_RED

/* Foreground blue color in the terminal.
 * void term_color_blue()
 * */
term_color_blue:
	TERM_FORMAT_PRINT A_OUTFORMAT_COLOR_BLUE, N_COLOR_BLUE

/* Background red color in the terminal.
 * void term_background_red()
 * */
term_background_red:
	TERM_FORMAT_PRINT A_OUTFORMAT_BACKGROUND_RED, N_BACKGROUND_RED

/* Background blue color in the terminal.
 * void term_background_blue()
 * */
term_background_blue:
	TERM_FORMAT_PRINT A_OUTFORMAT_BACKGROUND_BLUE, N_BACKGROUND_BLUE

/* Terminal blinking.
 * void term_style_blink()
 * */
term_style_blink:
	TERM_FORMAT_PRINT A_OUTFORMAT_STYLE_BLINK, N_STYLE_BLINK

/* Terminal rapid blinking.
 * void term_style_blink_rapid
 * */
term_style_blink_rapid:
	TERM_FORMAT_PRINT A_OUTFORMAT_STYLE_BLINK_RAPID, N_STYLE_BLINK_RAPID


/* This function should put the cursor to the given coordinates in the parameters.
 * we cannot simply call the code since the code itself is dependent on the given
 * parameters thus we first must compute the numbers into a char code and then generate
 * the code from it.
 * @I32 r: row position
 * @i32 c: col position
 * void term_moveto(I32 r, I32 c)
 * */
term_moveto:
	push {r4, r5, r6, fp, lr}
	mov fp, sp
	sub sp, sp, #0x40		// 64 bytes: 	32 bytes for two numbers
					// 		32 bytes for the final string
	mov r4, r1			// move c into r2 (save before call)

	mov r1, sp			// buffer into r1
	bl strings_convert_int_to_cstring
	mov r5, r0			// save the length of the first number

	add r1, sp, r5			// move by 16 bytes, second half of buffer
	add r1, r1, #1
	mov r0, r4			// second number
	bl strings_convert_int_to_cstring
	add r5, r5, r0			// num1_len + num2_len (used for printing)
	add r5, r5, #moveto_code_len
	sub r5, r5, #2


	add r6, sp, #0x20		// place to write the final string to
	ldr r0, moveto_code_adr		// load the code
	mov r2, sp			// load the the place of the first number

term_moveto_paste_in:
	ldrb r1, [r0], #1			// read character from the code
						// and move forward
//	push {r0, r1, r2, r3}
//	mov r0, r1
//	bl term_print_char2
//	pop {r0, r1, r2, r3}

	cmp r1, #CHAR_N_NUM			// compare against n
	beq term_moveto_paste_in_numbers	// if it is, then paste in the number	

	cmp r1, #NULL_TERM			// compare against '/0'	
	beq term_moveto_pre_end			// if it is, we are at the end

	strb r1, [r6], #1			// otherwise write the char 
						// into the buffer
	b term_moveto_paste_in
	
term_moveto_paste_in_numbers:
	ldrb r1, [r2], #1
	cmp r1, #NULL_TERM			// compare againt null terminator
//	addeq r2, r2, #1
	beq term_moveto_paste_in
	strb r1, [r6], #1			// put the number into the buffer
	b term_moveto_paste_in_numbers

term_moveto_pre_end:
	add r0, sp, #0x20			// put the buffer in r0
	mov r1, r5				// length
	sub r1, r1, #1
	bl term_print_known_string
	
term_moveto_end:
	add sp, sp, #0x40
	pop {r4, r5, r6, fp, lr}
	bx lr
moveto_code_adr:
	.word moveto_code

/* needs 8 bytes on stack
 * struct Win_Size 
 * { U16 ws_row;
 *   U16 ws_col;
 *   U16 ws_pixel_x
 *   U16 ws_pixel_y
 * }
 * */

/* Gets the size of the terminal
 * @I32 *row: pointer to paste the row value into
 * @I32 *col: pointe to paste the col value into
 * void term_get_size(I32 *row, I32 *col)
 * */
term_get_size:
	push {r4, r7, fp, lr}
	mov fp, sp
	sub sp, #0x08		// space for Win_Size

	mov r7, #SYS_IOCTL	// syscall code
	mov r4, r0		// save the register values before the syscall
	mov r3, r1
	mov r0, #STDIN_FILENO
	mov r1, #TIOCGWINSZ
	mov r2, sp
	SYSCALL

	mov r0, r4		// get them back
	mov r1, r3
	ldrh r2, [sp]		// read the values from the syscall
	ldrh r3, [sp, #2]
	str r2, [r0]		// write them into the pointers in the registers
	str r3, [r1]
	add sp, #0x08

	pop {r4, r7, fp, lr}	
	bx lr

/* need 60 bytes */
/* struct termios{
	tcflag_t c_iflag;
	tcflag_t c_oflag;
	tcflag_t c_cflag;
	tcflag_t c_lflag;
	cc_t c_line;
	cc_t c_cc[NCSS]; (#define NCSS 32)
	speed_t c_ispeed;
	speed_t c_ospeed;
}*/
/* tcflag_t term_noncanon()
 * @returns -> tcflag_t: flag to switch the terminal to an idle state 
 **/
term_noncanon:
	push {r7, fp, lr}
	mov fp, sp
	sub sp, #0x40		// 64 bytes, space for the structure
	
	mov r7, #SYS_IOCTL
	mov r0, #STDIN_FILENO
	mov r1, #TCGETS
	mov r2, sp
	SYSCALL

	ldr r3, [sp, #12]	// save the c_lflag
	mov r2, #ISIG
	str r2, [sp, #12]	// change the flag

	mov r7, #SYS_IOCTL	// update
	mov r0, #STDIN_FILENO
	mov r1, #TCSETS
	mov r2,	sp 
	SYSCALL

	add sp, #0x40
	pop {r7, fp, lr}
	mov r0, r3		// save the old flag for return
	bx lr

/* Sets the terminal back to its initial state,
 * used as analogous function to term_noncanon.
 * @tcflag_t old: previous flag
 * void term_canon(tcflag_t old)
 * */
term_canon:	
	push {r4, r7, fp, lr}
	mov fp, sp
	sub sp, #0x40		// 64 bytes, space for the structure
	mov r4, r0		// save the old flag

	mov r7, #SYS_IOCTL	// syscall prep
	mov r0, #STDIN_FILENO
	mov r1, #TCGETS
	mov r2, sp
	SYSCALL

	str r4, [sp, #12]	// put back the old flag in

	mov r7, #SYS_IOCTL	// syscall prep
	mov r0, #STDIN_FILENO
	mov r1, #TCSETS
	mov r2, sp
	SYSCALL

	add sp, #0x40
	pop {r4, r7, fp, lr}
	bx lr
/*
 * struct pollfd {
 *    int   fd;         
 *   short events;     
 *   short revents;    
 * }
 * */

/* Reads char from terminal input.
 * @int timeout: waits for the key.
 * @returns -> char: the input result
 * char term_read_char(int timeout)
 * */
term_read_char:
	push {r4,r7, fp, lr}
	sub sp, #0x10;		// reserved for poll structure and local variable
	mov r1, #STDIN_FILENO
	str r1, [sp]		// sets the file descriptor
	mov r2, #POLLIN
	strh r2, [sp, #4]	// sets the events to POLLIN

	mov r7, #SYS_POLL	// syscall prep
	mov r4, r0		// save timeout
	mov r0, sp
	mov r1, #1
	mov r2, r4
	SYSCALL

	//NOTE left off here, lower than 0, return negate -1, otherwise ...	
	cmp r0, #0
	blt term_read_char_lt
	ldrh r1, [sp, #6]
	and r1, r1, #POLLIN
	cmp r1, #0
	beq term_read_char_eq_zero
	add r1, sp, #8

	mov r0, #STDIN_FILENO	// syscall prep
	mov r7, #SYS_READ
	mov r2, #1		// read one char
	SYSCALL
	cmp r0, #0
	bgt term_read_char_ret_char
	b term_read_char_eq_zero

term_read_char_ret_char:
	ldrb r0, [sp, #8]
	b term_reach_char_end

term_read_char_eq_zero:
	mov r0, #0
	b term_reach_char_end

term_read_char_lt:
	mov r0, #-1

term_reach_char_end:
	add sp, #0x10
	pop {r4, r7, fp, lr}
	bx lr

/* Prints a string of unknown size.
 * @char *str: string to print
 * void term_print_string(char *str)
 * */
term_print_string:
	push {r0, r7, fp, lr}		// save r0 for printing out
	bl strings_strlen		// r0 = strlen(r0)
	mov r3, r0
	pop {r0}			// get back our text
	mov r1, r0
	mov r2, r3
	mov r7, #SYS_WRITE
	mov r0, #STDOUT_FILENO
	SYSCALL

	pop {r7, fp, lr}
	bx lr

/* Prints a string of known size.
 * @char *str: string to print
 * @U32 size: size of the string
 * void term_print_known_string(char *str, U32 size)
 * */
term_print_known_string:
	push {r7}
	mov r7, #SYS_WRITE
	mov r2, r0		// string
	mov r3, r1		// lenght of string
	mov r0, #STDOUT_FILENO	
	mov r1,	r2		// string parameter
	mov r2, r3		// string length parameter
	SYSCALL
	pop {r7}
	bx lr

/* Prints an integer.
 * @int val: integer value to print
 * void term_print_int(int val)
 * */
term_print_int:
	push {fp, lr}
	mov fp, sp

	/* NOTE this should be enough to allocate */
	sub sp, #0x80	// 128 bytes
	mov r1, sp
	bl strings_convert_int_to_cstring
	mov r1, r0
	mov r0, sp
	bl term_print_known_string
	add sp, #0x80
	pop {fp, lr}
	bx lr

/* Prints a character.
 * @char *c: character to print
 * void term_print_char(char *c)
 * */
term_print_char:
	push {fp, lr}
	mov r1, #1
	bl term_print_known_string
	pop {fp, lr}
	bx lr

/* Prints a character.
 * @char c: character pointer to print the dereferenced value of
 * void term_print_char2(char c)
 * */
term_print_char2:
	push {fp, lr}
	sub sp, #0x8
	mov r1, #1
	strb r0, [sp]
	mov r0, sp
	bl term_print_known_string
	add sp, #0x8
	pop {fp, lr}
	bx lr

/* Prints out a row of character c of a given color of some length.
 * @char c: character to print out in the row
 * @int len: length of the row
 * @int v_flag:	indicating what kind of decorations we want for the row
 * */
term_print_row:
	push {r4, r5, r6, fp, lr}
term_print_row_loop:
	cmp r1, #0
	beq term_print_row_end
	sub r1, r1, #1
	mov r4, r0
	mov r5, r1
	mov r6, r2
	bl term_print_char2
	mov r0, r4
	mov r1, r5
	mov r2, r6	
	b term_print_row_loop
term_print_row_end:
	pop {r4, r5, r6, fp, lr}
	bx lr
	
/* Prints out a square made of character c of a given color of some size.
 * @char c: character to use for the square
 * @int color: macro value for a color
 * @int size_x: width of the rectangle
 * @int size_y: height of the rectangle
 * @int border: should we only print out the border of the rectangle
 * void term_print_rect()
 * */
term_print_rect:
	push {r4, r5, r6, fp, lr}
	mov fp, sp
	mov r4, r2		// size_x
	mov r5, r3		// size_y
	ldr r6, [fp]		// border	
term_print_rect_loop_y:
	cmp r5, #0
	beq term_print_rect_end
	push {r0}
	mov r1, r4
	bl term_print_row
	mov r0, #'\n'
	bl term_print_char2
	sub r5, r5, #1
	pop {r0}
	b term_print_rect_loop_y
term_print_rect_end:
	pop {r4, r5, r6, fp, lr}
	bx lr

/* Prints out a square made of character c of a given color of some size.
 * @char c: character to use for the square
 * @int color: macro value for a color
 * @int size: size of the square
 * @int border: should we only print out the border of the square
 * void term_print_square()
 * */
term_print_square:

.endif	/* TERM_ASM */
