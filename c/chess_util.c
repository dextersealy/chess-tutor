#include <ruby.h>
#include "extconf.h"
#include <stdio.h>

//  H e l p e r   f u n c t i o n s

//  Retrieve color of board piece

char get_color_at(VALUE board, int row, int col) {
  VALUE iv_board = rb_iv_get(board, "@board");
  VALUE piece = rb_ary_entry(iv_board, row * 8 + col);
  VALUE color = rb_iv_get(piece, "@color");
  return (TYPE(color) == T_NIL) ? ' ' : *rb_id2name(SYM2ID(color));
}

//  Test if piece occupies board position

int is_occupied(VALUE board, int row, int col) {
  return get_color_at(board, row, col) != ' ';
}

//  Test if board position is valid and, empty or is_occupied by
//  an opposing piece

int is_valid_pos(VALUE board, int row, int col, char piece) {
  return 0 <= row && row < 8 && 0 <= col && col < 8 &&
    piece != get_color_at(board, row, col);
}

//  Append position to Ruby array

void add_move(VALUE moves, int row, int col) {
  VALUE pos = rb_ary_new_capa(2);
  rb_ary_store(pos, 0, INT2NUM(row));
  rb_ary_store(pos, 1, INT2NUM(col));
  rb_ary_push(moves, pos);
}

//  Get dx, dy vector for a direction

static int *get_delta(const char *dir_name) {
  static struct direction {
    const char *name;
    int delta[2];
  } directions[] = {
    {"up", {-1,  0}}, {"down", {1, 0}}, {"right", {0, 1}}, {"left", {0, -1}},
    {"nw", {-1, -1}}, {"ne", {-1, 1}}, {"sw", {1, -1}}, {"se", {1, 1}}
  };

  for (int i = sizeof(directions) / sizeof(directions[0]); i--;) {
    if (strcmp(directions[i].name, dir_name) == 0) {
      return directions[i].delta;
    }
  }
  return 0;
}

//  M o d u l e   i n t e r f a c e

//  Test if a position is on the board

static VALUE in_bounds(int argc, VALUE *argv, VALUE self)
{
  VALUE pos = argv[0];
  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  if (row >= 0 && row < 8 && col >= 0 && col < 8) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

//  Retrieve a piece on the board

static VALUE get_piece_at(int argc, VALUE *argv, VALUE self)
{
  VALUE board = argv[0];
  VALUE pos = argv[1];
  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  return rb_ary_entry(board, row * 8 + col);
}

//  Generate moves for a stepping (K) or sliding piece (N, R, B, Q)

static VALUE get_moves(int argc, VALUE *argv, VALUE self)
{
  VALUE pos = argv[0];
  VALUE ary = argv[1];
  VALUE stepping = strcmp(rb_id2name(SYM2ID(argv[2])), "step") == 0;
  VALUE board = argv[3];

  int start_row = NUM2INT(rb_ary_entry(pos, 0));
  int start_col = NUM2INT(rb_ary_entry(pos, 1));

  VALUE moves = rb_ary_new();
  if (is_valid_pos(board, start_row, start_col, 0)) {
    char color = get_color_at(board, start_row, start_col);
    for (int i = 0, n = RARRAY_LEN(ary); i < n; i++) {
      int *d = get_delta(rb_id2name(SYM2ID(rb_ary_entry(ary, i))));
      if (d != 0) {
        int dy = d[0], dx = d[1];
        for (int row = start_row + dy, col = start_col + dx
          ; is_valid_pos(board, row, col, color)
          ; row += dy, col += dx) {
          add_move(moves, row, col);
          if (stepping || is_occupied(board, row, col)) {
            break;
          }
        }
      }
    }
  }
  return moves;
}

//  Generate the moves for a pawn

static VALUE get_pawn_moves(int argc, VALUE *argv, VALUE self)
{
  VALUE pos = argv[0];
  VALUE board = argv[1];
  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  char color = get_color_at(board, row, col);
  int step = (color == 'b') ? 1 : -1;

  VALUE moves = rb_ary_new();

  //  pawn's step moves

  int on_home_row = (color == 'b' && row == 1) || (color == 'w' && row == 6);
  for (int dy = step, n = on_home_row ? 2 : 1; n--; dy += step) {
    if (is_valid_pos(board, row + dy, col, color) &&
      !is_occupied(board, row + dy, col)) {
      add_move(moves, row + dy, col);
    } else {
      break;
    }
  }

  //  pawn's capture moves

  if (is_valid_pos(board, row + step, col - 1, color) &&
    is_occupied(board, row + step, col - 1)) {
    add_move(moves, row + step, col - 1);
  }
  if (is_valid_pos(board, row + step, col + 1, color) &&
    is_occupied(board, row + step, col + 1)) {
    add_move(moves, row + step, col + 1);
  }

  return moves;
}

//  Generate moves for a knight

static VALUE get_knight_moves(int argc, VALUE *argv, VALUE self)
{
  static int MOVES[][2] = {
    {-2, -1}, {-2, 1}, {-1, -2}, {-1, 2}, {1, -2}, {1, 2}, {2, -1}, {2, 1}
  };

  VALUE pos = argv[0];
  VALUE board = argv[1];
  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  char color = get_color_at(board, row, col);

  VALUE moves = rb_ary_new();
  for (int i = 0, n = sizeof(MOVES) / sizeof(MOVES[0]); i < n; i++) {
    int dy = MOVES[i][0], dx = MOVES[i][1];
    if (is_valid_pos(board, row + dy, col + dx, color)) {
      add_move(moves, row + dy, col + dx);
    }
  }
  return moves;
}

static VALUE rbModule;

//  Module initialization function called by Ruby

void Init_chess_util()
{
	rbModule = rb_define_module("ChessUtil");
  rb_define_module_function(rbModule, "in_bounds", in_bounds, -1);
  rb_define_module_function(rbModule, "get_piece_at", get_piece_at, -1);
  rb_define_module_function(rbModule, "get_moves", get_moves, -1);
  rb_define_module_function(rbModule, "get_pawn_moves", get_pawn_moves, -1);
  rb_define_module_function(rbModule, "get_knight_moves", get_knight_moves, -1);
}
