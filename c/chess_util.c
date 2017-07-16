#include <ruby.h>
#include "extconf.h"
#include <stdio.h>

//  H e l p e r   f u n c t i o n s

static VALUE get_board_ary(VALUE piece) {
  return rb_iv_get(rb_iv_get(piece, "@board"), "@board");
}

//  Get color of board piece; returns 'b' and 'w' for black and white
//  pieces and ' ' for empty space

static char get_color_at(VALUE board_ary, int row, int col) {
  VALUE piece = rb_ary_entry(board_ary, row * 8 + col);
  VALUE color = rb_iv_get(piece, "@color");
  return (TYPE(color) == T_NIL) ? ' ' : *rb_id2name(SYM2ID(color));
}

//  Test if board position contains a piece

static int is_occupied(VALUE board_ary, int row, int col) {
  VALUE piece = rb_ary_entry(board_ary, row * 8 + col);
  return strcmp(rb_obj_classname(piece), "NullPiece") != 0;
}

//  Test if board position is valid move for a color

int is_valid_pos(VALUE board_ary, int row, int col, char color) {
  return 0 <= row && row < 8 && 0 <= col && col < 8 &&
    color != get_color_at(board_ary, row, col);
}

//  Append position to Ruby array

void add_move(VALUE moves, int row, int col) {
  VALUE pos = rb_ary_new_capa(2);
  rb_ary_store(pos, 0, INT2NUM(row));
  rb_ary_store(pos, 1, INT2NUM(col));
  rb_ary_push(moves, pos);
}

//  Search for position in Ruby array

int find_move(VALUE moves, int row, int col) {
  int n = TYPE(moves) == T_NIL ? 0 : RARRAY_LEN(moves);
  while (n--) {
    VALUE pos = rb_ary_entry(moves, n);
    if (NUM2INT(rb_ary_entry(pos, 0)) == row &&
      NUM2INT(rb_ary_entry(pos, 1)) == col) {
      break;
    }
  }
  return n;
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

//  Piece tables for evaluating boards

static struct piece_table {
  const char *type;
  int base;
  int loc[64];
} PIECE_TABLES[] = {
  { "Pawn", 100, {
    0,   0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
    0,   0,  0, 20, 20,  0,  0,  0,
    5,   5, 10, 25, 25, 10,  5,  5,
    5,  -5,-10,  0,  0,-10, -5,  5,
    5,  10, 10,-20,-20, 10, 10,  5,
    0,   0,  0,  0,  0,  0,  0,  0
  }},
  { "Knight", 300, {
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  0,  0,  0,-20,-40,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -30,  5, 15, 20, 20, 15,  5,-30,
    -30,  0, 15, 20, 20, 15,  0,-30,
    -30,  5, 10, 15, 15, 10,  5,-30,
    -40,-20,  0,  5,  5,  0,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50
  }},
  { "Bishop", 300, {
    -20,-10,-10,-10,-10,-10,-10,-20,
    -10,  0,  0,  0,  0,  0,  0,-10,
    -10,  0,  5, 10, 10,  5,  0,-10,
    -10,  5,  5, 10, 10,  5,  5,-10,
    -10,  0, 10, 10, 10, 10,  0,-10,
    -10, 10, 10, 10, 10, 10, 10,-10,
    -10,  5,  0,  0,  0,  0,  5,-10,
    -20,-10,-10,-10,-10,-10,-10,-20
  }},
  { "Rook", 500, {
     0,  0,  0,  0,  0,  0,  0,  0,
     5, 10, 10, 10, 10, 10, 10,  5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
     0,  0,  0,  5,  5,  0,  0,  0
  }},
  { "Queen", 900, {
    -20,-10,-10, -5, -5,-10,-10,-20,
    -10,  0,  0,  0,  0,  0,  0,-10,
    -10,  0,  5,  5,  5,  5,  0,-10,
     -5,  0,  5,  5,  5,  5,  0, -5,
      0,  0,  5,  5,  5,  5,  0, -5,
    -10,  5,  5,  5,  5,  5,  0,-10,
    -10,  0,  5,  0,  0,  0,  0,-10,
    -20,-10,-10, -5, -5,-10,-10,-20
  }},
  { "King", 9000, {
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -20,-30,-30,-40,-40,-30,-30,-20,
    -10,-20,-20,-20,-20,-20,-20,-10,
     20, 20,  0,  0,  0,  0, 20, 20,
     20, 30, 10,  0,  0, 10, 30, 20
  }}
};

//  Get the table for a piece

struct piece_table *get_piece_table(const char *type) {
  for (int i = 0, n = sizeof(PIECE_TABLES) / sizeof(PIECE_TABLES[0]); i < n; i++) {
    if (strcmp(type, PIECE_TABLES[i].type) == 0) {
      return &PIECE_TABLES[i];
    };
  }
  return 0;
}

//  Calculate the value of a piece to a player; offset is the piece's linear
//  board position (i.e., row * 8 + col)

int get_piece_value(VALUE piece, int offset, char player) {
  int value = 0;

  const char *type = rb_obj_classname(piece);
  if (strcmp(type, "NullPiece") != 0) {
    struct piece_table *table = get_piece_table(type);
    if (table) {
      char color = *rb_id2name(SYM2ID(rb_iv_get(piece, "@color")));
      value = table->base + table->loc[(color == 'w') ? offset : (63 - offset)];
      if (color != player) {
        value = -value;
      }
    }
  }

  return value;
}

//  Test whether a series of board postions is unoccupied

static int not_occupied(VALUE ary, int row, int start_col, int end_col) {
  for (int i = start_col; i <= end_col; i++) {
    VALUE piece = rb_ary_entry(ary, row * 8 + i);
    if (TYPE(rb_iv_get(piece, "@color")) != T_NIL) {
      return 0;
    }
  }
  return 1;
}

//  M o d u l e   i n t e r f a c e

//  Test if a position valid; accepts array with [row, col] coordinates.
//  Verifies the input is an array of the correct size and the coordinates
//  are on the board

static VALUE in_bounds(int argc, VALUE *argv, VALUE self) {
  VALUE pos = argv[0];

  if (TYPE(pos) == T_ARRAY && RARRAY_LEN(pos) == 2) {
    int row = NUM2INT(rb_ary_entry(pos, 0));
    int col = NUM2INT(rb_ary_entry(pos, 1));
    if (row >= 0 && row < 8 && col >= 0 && col < 8) {
      return Qtrue;
    }
  }

  return Qfalse;
}

//  Retrieve a piece on the board; takes array of pieces, and array with
//  [row, col] coordinates

static VALUE get_piece_at(int argc, VALUE *argv, VALUE self) {
  int row = NUM2INT(rb_ary_entry(argv[1], 0));
  int col = NUM2INT(rb_ary_entry(argv[1], 1));
  if (row >= 0 && row < 8 && col >= 0 && col < 8) {
    return rb_ary_entry(argv[0], row * 8 + col);
  } else {
    return Qnil;
  }
}

//  Set a piece on the board; takes array of pieces, array with
//  [row, col] coordinates, and Piece

static VALUE set_piece_at(int argc, VALUE *argv, VALUE self) {
  int row = NUM2INT(rb_ary_entry(argv[1], 0));
  int col = NUM2INT(rb_ary_entry(argv[1], 1));
  rb_ary_store(argv[0], row * 8 + col, argv[2]);
  return argv[2];
}

//  Generate moves for a stepping or sliding piece; takes Piece object,
//  array of movements (any of :down, :up, :left, :right, :nw, :ne, :sw, :se),
//  and whether to step or slide (one of :slide, :step)

static VALUE get_moves(int argc, VALUE *argv, VALUE self) {
  VALUE moves = rb_ary_new();
  VALUE piece = argv[0];
  VALUE movements = argv[1];
  VALUE stepping = strcmp(rb_id2name(SYM2ID(argv[2])), "step") == 0;

  VALUE board_ary = get_board_ary(piece);
  VALUE pos = rb_iv_get(piece, "@current_pos");
  int start_row = NUM2INT(rb_ary_entry(pos, 0));
  int start_col = NUM2INT(rb_ary_entry(pos, 1));

  if (is_valid_pos(board_ary, start_row, start_col, 0)) {
    char color = get_color_at(board_ary, start_row, start_col);
    for (int i = 0, n = RARRAY_LEN(movements); i < n; i++) {
      int *d = get_delta(rb_id2name(SYM2ID(rb_ary_entry(movements, i))));
      if (d != 0) {
        int dy = d[0], dx = d[1];
        for (int row = start_row + dy, col = start_col + dx
          ; is_valid_pos(board_ary, row, col, color)
          ; row += dy, col += dx) {
          add_move(moves, row, col);
          if (stepping || is_occupied(board_ary, row, col)) {
            break;
          }
        }
      }
    }
  }

  return moves;
}

//  Generate the moves for a pawn; takes Pawn object

static VALUE get_pawn_moves(int argc, VALUE *argv, VALUE self) {
  VALUE moves = rb_ary_new();
  VALUE pawn = argv[0];

  VALUE board_ary = get_board_ary(pawn);
  VALUE pos = rb_iv_get(pawn, "@current_pos");
  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  char color = get_color_at(board_ary, row, col);
  int step = (color == 'b') ? 1 : -1;

  //  pawn's step moves

  int on_home_row = (color == 'b' && row == 1) || (color == 'w' && row == 6);
  for (int dy = step, n = on_home_row ? 2 : 1; n--; dy += step) {
    if (is_valid_pos(board_ary, row + dy, col, color) &&
      !is_occupied(board_ary, row + dy, col)) {
      add_move(moves, row + dy, col);
    } else {
      break;
    }
  }

  //  pawn's capture moves

  if (is_valid_pos(board_ary, row + step, col - 1, color) &&
    is_occupied(board_ary, row + step, col - 1)) {
    add_move(moves, row + step, col - 1);
  }
  if (is_valid_pos(board_ary, row + step, col + 1, color) &&
    is_occupied(board_ary, row + step, col + 1)) {
    add_move(moves, row + step, col + 1);
  }

  return moves;
}

//  Generate moves for a knight; takes Knight object

static int KNIGHT_MOVES[][2] = {
  {-2, -1}, {-2, 1}, {-1, -2}, {-1, 2}, {1, -2}, {1, 2}, {2, -1}, {2, 1}
};

static VALUE get_knight_moves(int argc, VALUE *argv, VALUE self) {
  VALUE moves = rb_ary_new();
  VALUE knight = argv[0];

  VALUE board_ary = get_board_ary(knight);
  VALUE pos = rb_iv_get(knight, "@current_pos");
  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  char color = get_color_at(board_ary, row, col);

  for (int i = 0, n = sizeof(KNIGHT_MOVES) / sizeof(KNIGHT_MOVES[0]); i < n; i++) {
    int dy = KNIGHT_MOVES[i][0], dx = KNIGHT_MOVES[i][1];
    if (is_valid_pos(board_ary, row + dy, col + dx, color)) {
      add_move(moves, row + dy, col + dx);
    }
  }

  return moves;
}

//  Generate King's moves; takes King object

static VALUE get_king_moves(int argc, VALUE *argv, VALUE self) {
  VALUE moves = rb_ary_new();
  VALUE king = argv[0];

  VALUE board = rb_iv_get(king, "@board");
  VALUE board_ary = rb_iv_get(board, "@board");
  VALUE castleable =  rb_iv_get(board, "@castleable");
  VALUE pos = rb_iv_get(king, "@current_pos");
  int row = NUM2INT(rb_ary_entry(pos, 0));
  int col = NUM2INT(rb_ary_entry(pos, 1));
  char color = get_color_at(board_ary, row, col);

  for (int dy = -1; dy <= 1; dy++) {
    for (int dx = -1; dx <= 1; dx ++) {
      if ((dx || dy) && is_valid_pos(board_ary, row + dy, col + dx, color)) {
        add_move(moves, row + dy, col + dx);
      }
    }
  }

  if (find_move(castleable, row, 0) >= 0
    && not_occupied(board_ary, row, 1, col - 1)) {
    add_move(moves, row, col - 2);
  }

  if (find_move(castleable, row, 7) >= 0
    && not_occupied(board_ary, row, col + 1, 6)) {
    add_move(moves, row, col + 2);
  }

  return moves;
}

//  Calculate the value of a board; takes Board object and player color.

static VALUE get_board_value(int argc, VALUE *argv, VALUE self) {
  int value = 0;

  VALUE board_ary = rb_iv_get(argv[0], "@board");
  char player = *rb_id2name(SYM2ID(argv[1]));

  for (int i = 0; i < 64; i++) {
    value += get_piece_value(rb_ary_entry(board_ary, i), i, player);
  }

  return INT2NUM(value);
}

//  Test if array of moves inclues a position; takes array of [row, col]
//  moves and a [row, col] position

static VALUE moves_include(int argc, VALUE *argv, VALUE self) {
  VALUE moves = argv[0];
  int row = NUM2INT(rb_ary_entry(argv[1], 0));
  int col = NUM2INT(rb_ary_entry(argv[1], 1));
  return find_move(moves, row, col) < 0 ? Qfalse : Qtrue;
}

//  M o d u l e  s e t u p

//  Initialization function called by Ruby

static VALUE rbModule;

void Init_chess_util() {
	rbModule = rb_define_module("ChessUtil");
  rb_define_module_function(rbModule, "in_bounds", in_bounds, -1);
  rb_define_module_function(rbModule, "get_piece_at", get_piece_at, -1);
  rb_define_module_function(rbModule, "set_piece_at", set_piece_at, -1);
  rb_define_module_function(rbModule, "get_moves", get_moves, -1);
  rb_define_module_function(rbModule, "get_pawn_moves", get_pawn_moves, -1);
  rb_define_module_function(rbModule, "get_knight_moves", get_knight_moves, -1);
  rb_define_module_function(rbModule, "get_king_moves", get_king_moves, -1);
  rb_define_module_function(rbModule, "get_board_value", get_board_value, -1);
  rb_define_module_function(rbModule, "moves_include", moves_include, -1);
}
