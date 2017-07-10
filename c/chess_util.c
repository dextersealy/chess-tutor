#include <ruby.h>
#include "extconf.h"

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

static VALUE add(int argc, VALUE *argv, VALUE self)
{
  VALUE pos = argv[0];
  VALUE delta = argv[1];
  int x = NUM2INT(rb_ary_entry(pos, 0));
  int y = NUM2INT(rb_ary_entry(pos, 1));
  int dx = NUM2INT(rb_ary_entry(delta, 0));
  int dy = NUM2INT(rb_ary_entry(delta, 1));
  VALUE arr = rb_ary_new_capa(2);
  rb_ary_store(arr, 0, INT2NUM(x + dx));
  rb_ary_store(arr, 1, INT2NUM(y + dy));
  return arr;
}

static VALUE rbModule;

void Init_chess_util()
{
	rbModule = rb_define_module("ChessUtil");
	rb_define_module_function(rbModule, "in_bounds", in_bounds, -1);
	rb_define_module_function(rbModule, "add", add, -1);
}
