require_relative 'piece.rb'
require_relative 'stepping_piece.rb'
require_relative '../c/chess_util'

require 'byebug'

class King < Piece

  def moves
    ChessUtil::get_king_moves(self);
  end

  def valid_moves
    result = super
    result.reject! do |pos|
      row, col, end_col = *current_pos, pos[1]
      (end_col - col).abs == 2 && (board.in_check?(color) ||
        !result.include?([row, (col + end_col) / 2]))
    end
    result
  end

  def to_s
    (color == :white) ? "\u2654" : "\u265A"
  end
end
