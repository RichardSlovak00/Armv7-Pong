#ifndef PONG_LED_H
#define PONG_LED_H

#include <fcntl.h>
#include <inttypes.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <assert.h>

#define PLED_WIDTH (8)
#define PLED_HEIGHT (8)
#define PLED_MAX_PLAYER_SIZE PLED_HEIGHT

#define PLED_LED_PATH "/dev/fb0"

#define PLED_ERROR_DEVICE_INFO "unable to obtain device info\n"
#define PLED_ERROR_FRAME_BUFFER "unable to open frame buffer\n"
#define PLED_ERROR_FRAME_BUFFER_MAP "unable to map frame buffer\n"

/* This needs to match the value in the assembly file */
#ifndef PLED_PLAYER_SIZE
#define PLED_PLAYER_SIZE	5
#endif /* PLED_PLAYER_SIZE */

#ifndef PLED_PLAYER_1_COLOR
#define PLED_PLAYER_1_COLOR	0x00FF
#endif /* PLED_PLAYER_1_COLOR */

#ifndef PLED_PLAYER_2_COLOR
#define PLED_PLAYER_2_COLOR	0xFF00
#endif /* PLED_PLAYER_2_COLOR */

#ifndef PLED_BALL_COLOR
#define PLED_BALL_COLOR		0x0FF0
#endif /* PLED_BALL_COLOR */

#define PLED_PLAYER_DOWN	1
#define PLED_PLAYER_UP		-1
#define PLED_SIDE_LEFT		-1
#define PLED_SIDE_RIGHT		1
#define PLED_SIDE_NONE		0

#ifdef PLED_BALL_CHANGE
#ifndef PLED_BALL_CHANGE_FREQ
#define PLED_BALL_CHANGE_FREQ	1000
#endif /* PLED_BALL_CHANGE_FREQ */
#endif /* PLED_BALL_CHANGE */

#define PLED_NO_PRINT	1

typedef int16_t I16;
typedef uint16_t U16;
typedef int32_t I32;
typedef uint32_t U32;

typedef struct Game {
	I32 rows;	// row count of the game
	I32 cols;	// col count of the game
	I32 ball_r;	// row pos of the ball
	I32 ball_c;	// col pos of the ball
	I32 ball_dir_r;	// row dir of the ball
	I32 ball_dir_c;	// col dir of the ball
	I32 player1;	// left player
	I32 player2;	// right player
} Game;

static inline U16 *pled_frame_buffer_map(I32 fd) {
	return mmap(NULL, PLED_WIDTH * PLED_HEIGHT * 2, 
		PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
}

/* Calculates the index in the frame buffer given the x and y coordinates.
 * @I32 x: x coordinate
 * @I32 y : y coordinate
 * @returns -> I32: the calculated index
 * */
static inline I32 pled_index(I32 x, I32 y) {
	return (y * PLED_WIDTH) + x;
}

/* Puts a pixel of a given color and a given coordinate.
 * @U16 *frame_buffer: mapped frame buffer memory
 * @U16 color: color value to use
 * @I32 x: x coordinate
 * @I32 y: y coordinate
 * */
static inline void pled_frame_buffer_put_pixel(U16 *frame_buffer,
				U16 color, I32 x, I32 y) {
	frame_buffer[pled_index(x,y)] = color;
}

/* Frees the led in a sense that it gets all colored to one color
 * @U16 *frame_buffer: mapped memory
 * @U16 color: color to use
 * */
static inline void pled_frame_buffer_free_all(U16 *frame_buffer,
				U16 color) {
	for (I32 i = 0; i < PLED_WIDTH * PLED_HEIGHT; i++) {
		frame_buffer[i] = color;
	}
}

static inline Game pled_game_create() {
	return (Game){
			.rows = PLED_WIDTH,
			.cols = PLED_HEIGHT,
			.ball_r = 3,
			.ball_c = 3,
			.ball_dir_r = 1,
			.ball_dir_c = -1,
			.player1 = 3,
			.player2 = 3};
}

/* Draws the game according to the info in the game struct.
 * @Game *game: game struct pointer
 * */
void pled_draw_game(Game *game, U16 *frame_buffer);

/* Draws a player given the position and side, which termines player 1/2.
 * @Game *game: game data
 * @I32 position: position of player
 * @I32 side: side of player
 * */
void pled_draw_player(Game *game, U16 *frame_buffer, I32 side);

/* Moves player to given terminal coordinates.
 * @Game *game: game data
 * @I32 side: side of player to move
 * @I32 dir: direction to which move to (up down)
 * */
void pled_move_player(Game *game, U16 *frame_buffer, I32 side, I32 dir);

/* Moves the ball to the corresponding position in terminal
 * and determines if any player won/lost
 * @Game *game: game pointer to get data from
 * @returns -> int: values which determine whether someone won
 * */
I32 pled_move_ball(Game *game, U16 *frame_buffer);

/* Starts a game of pong.
 * @I32 joystick: one of the players can play on the joystick
 * @I32 player: player which can play on the joystick
 * */
void pled_start_game(I32 joystick, I32 player);

#endif /* PONG_LED_H */
