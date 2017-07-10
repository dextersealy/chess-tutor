#!/usr/bin/env ruby
require 'mkmf'

# preparation for compilation goes here

create_header
create_makefile 'chess_util'
