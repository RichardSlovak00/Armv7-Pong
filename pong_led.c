#include "pong_led.h"

/* We only need to replace the draw functions,
 * as those are the only ones dependent on terminal visualizations
 * */
extern I32 move_ball(Game *game);
extern void move_player(Game *game, I32 side, I32 dir);
extern char term_read_char(I32 timespan);
extern U32 term_noncanon();
extern void term_canon(U32 before);

void pled_draw_game(Game *game, U16 *frame_buffer) {
  for (I32 col = 0; col < game->cols; col++) {
    pled_frame_buffer_put_pixel(frame_buffer, 0xF00F, 0, col);
    pled_frame_buffer_put_pixel(frame_buffer, 0xF00F, game->rows - 1, col);
  }
  for (I32 row = 0; row < game->rows; row++) {
    pled_frame_buffer_put_pixel(frame_buffer, 0xF00F, row, 0);
    pled_frame_buffer_put_pixel(frame_buffer, 0xF00F, row, game->cols - 1);
  }
}

void pled_draw_player(Game *game, U16 *frame_buffer, I32 side) {
  assert(PLED_PLAYER_SIZE <= 8);
  I32 position = 0;
  I32 x = 1;
  U16 color = 0x0;
  if (side == PLED_SIDE_LEFT) {
    x = 1;
    color = PLED_PLAYER_1_COLOR;
    position = game->player1;
  } else {
    x = game->cols - 2;
    printf("%i\n", x);
    color = PLED_PLAYER_2_COLOR;
    position = game->player2;
  }

  I32 player_size = PLED_PLAYER_SIZE;
  for (I32 y = 0; y < player_size; y++) {
    pled_frame_buffer_put_pixel(frame_buffer, color, x, y + position);
  }
}

void pled_move_player(Game *game, U16 *frame_buffer, I32 side, I32 dir) {
  I32 x = 0;
  I32 y = 0;
  U16 color = 0x0;
  I32 prev_y = 0;

  // this should be a pointer
  I32 player;
  if (side == PLED_SIDE_LEFT) {
    x = 1;
    color = PLED_PLAYER_1_COLOR;
    player = game->player1;
  } else {
    x = game->cols - 2;
    color = PLED_PLAYER_2_COLOR;
    player = game->player2;
  }
  printf("PLAYER: %i\n", player);

  if (dir == PLED_PLAYER_UP) {
    if (player - 1 == 0) {
      return;
    }
    prev_y = player + PLED_PLAYER_SIZE - 1;
    y = player - 1;
  } else {
    if (player + PLED_PLAYER_SIZE >= PLED_HEIGHT) {
      return;
    }
    prev_y = player;
    y = player + PLED_PLAYER_SIZE;
  }

  // this should be inside the branches instead
  move_player(game, side, dir);
  printf("PREV_Y: %i, Y: %i\n", prev_y, y);
  pled_frame_buffer_put_pixel(frame_buffer, 0x0, x, prev_y);
  pled_frame_buffer_put_pixel(frame_buffer, color, x, y);
}

I32 pled_move_ball(Game *game, U16 *frame_buffer) {
  pled_frame_buffer_put_pixel(frame_buffer, 0x0, game->ball_c, game->ball_r);
  I32 ret = move_ball(game);
  pled_frame_buffer_put_pixel(frame_buffer, PLED_BALL_COLOR, game->ball_c,
                              game->ball_r);
  return ret;
}

void pled_start_game(I32 joystick, I32 player) {
  I32 fd = open(PLED_LED_PATH, O_RDWR);
  assert(fd >= 0);
  struct fb_fix_screeninfo fb_info;

  assert(ioctl(fd, FBIOGET_FSCREENINFO, &fb_info) != -1);

  U16 *frame_buffer = pled_frame_buffer_map(fd);
  assert(frame_buffer != NULL);

  pled_frame_buffer_free_all(frame_buffer, 0);

  Game game = pled_game_create();
  pled_draw_game(&game, frame_buffer);
  pled_draw_player(&game, frame_buffer, PLED_SIDE_LEFT);
  pled_draw_player(&game, frame_buffer, PLED_SIDE_RIGHT);

  U32 bef = term_noncanon();

  while (1) {
    char c = term_read_char(100);
    switch (c) {
    case 'x':
      goto exit_loop;
    case 'q':
      pled_move_player(&game, frame_buffer, PLED_SIDE_LEFT, PLED_PLAYER_UP);
      break;
    case 'a':
      pled_move_player(&game, frame_buffer, PLED_SIDE_LEFT, PLED_PLAYER_DOWN);
      break;
    case 'p':
      pled_move_player(&game, frame_buffer, PLED_SIDE_RIGHT, PLED_PLAYER_UP);
      break;
    case 'l':
      pled_move_player(&game, frame_buffer, PLED_SIDE_RIGHT, PLED_PLAYER_DOWN);
      break;
    }

    I32 side = pled_move_ball(&game, frame_buffer);
    if (0 /*side == PLED_SIDE_NONE*/) {
    exit_loop:
      break;
    }
  }
  term_canon(bef);
  munmap(frame_buffer, PLED_WIDTH * PLED_HEIGHT * 2);
  close(fd);
}
