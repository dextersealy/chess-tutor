#include <ruby.h>
#include "extconf.h"
#include <stdio.h>

//  H e l p e r   f u n c t i o n s

//  Retrieve color of board piece

char color_at(VALUE board, int row, int col) {
  VALUE iv_board = rb_iv_get(board, "@board");
  VALUE piece = rb_ary_entry(iv_board, row * 8 + col);
  VALUE color = rb_iv_get(piece, "@color");
  return (TYPE(color) == T_NIL) ? ' ' : *rb_id2name(SYM2ID(color));
}

//  Test if piece occupies board position

int occupied(VALUE board, int row, int col) {
  return color_at(board, row, col) != ' ';
}

//  Test if board position is valid and, empty or occupied by
//  an opposing piece

int valid_pos(VALUE board, int row, int col, char piece) {
  return 0 <= row && row < 8 && 0 <= col && col < 8 &&
    piece != color_at(board, row, col);
}

//  Append position to Ruby array

void add_move(VALUE moves, int row, int col) {
  VALUE pos = rb_ary_new_capa(2);
  rb_ary_store(pos, 0, INT2NUM(row));
  rb_ary_store(pos, 1, INT2NUM(col));
  rb_ary_push(moves, pos);
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

//  Offset a board coordinate

static VALUE add(int argc, VALUE *argv, VALUE self)
{
  VALUE pos = argv[0];
  VALUE delta = argv[1];
  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  int dy = NUM2INT(rb_ary_entry(delta, 0));
  int dx = NUM2INT(rb_ary_entry(delta, 1));
  VALUE arr = rb_ary_new_capa(2);
  rb_ary_store(arr, 0, INT2NUM(row + dy));
  rb_ary_store(arr, 1, INT2NUM(col + dx));
  return arr;
}

//  Retrieve a piece on the board

static VALUE get_piece_at(int argc, VALUE *argv, VALUE self)
{
  VALUE pos = argv[1];
  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  return rb_ary_entry(argv[0], row * 8 + col);
}

//  Generate partial moves for a sliding piece

static VALUE get_sliding_moves(int argc, VALUE *argv, VALUE self)
{
  VALUE pos = argv[0];
  VALUE dir = argv[1];
  VALUE board = argv[2];

  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  int dy = NUM2INT(rb_ary_entry(dir, 0));
  int dx = NUM2INT(rb_ary_entry(dir, 1));

  VALUE moves = rb_ary_new();
  if (valid_pos(board, row, col, 0)) {
    char color = color_at(board, row, col);
    for (row += dy, col += dx; valid_pos(board, row, col, color)
      ; row += dy, col += dx) {
      add_move(moves, row, col);
      if (occupied(board, row, col)) {
        break;
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
  char color = color_at(board, row, col);

  VALUE moves = rb_ary_new();

  //  pawn's step moves

  int on_home_row = (color == 'b' && row == 1) || (color == 'w' && row == 6);
  for (int step = 1; step <= (on_home_row ? 2 : 1); step++) {
    int new_row = (color == 'b') ? row + step : row - step;
    if (valid_pos(board, new_row, col, color) && !occupied(board, new_row, col)) {
      add_move(moves, new_row, col);
    } else {
      break;
    }
  }

  //  pawn's capture moves

  int step = 1;
  if (color == 'w') {
    step = -1;
  }
  if (valid_pos(board, row + step, col - 1, color) &&
    occupied(board, row + step, col - 1)) {
    add_move(moves, row + step, col - 1);
  }
  if (valid_pos(board, row + step, col + 1, color) &&
    occupied(board, row + step, col + 1)) {
    add_move(moves, row + step, col + 1);
  }

  return moves;
}

static VALUE rbModule;

//  Module initialization function called by Ruby

void Init_chess_util()
{
	rbModule = rb_define_module("ChessUtil");
	rb_define_module_function(rbModule, "in_bounds", in_bounds, -1);
	rb_define_module_function(rbModule, "add", add, -1);
  rb_define_module_function(rbModule, "get_piece_at", get_piece_at, -1);
  rb_define_module_function(rbModule, "get_sliding_moves", get_sliding_moves, -1);
  rb_define_module_function(rbModule, "get_pawn_moves", get_pawn_moves, -1);
}
