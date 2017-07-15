require_relative 'piece.rb'
require_relative 'stepping_piece.rb'
require_relative '../c/chess_util'

class King < Piece
  include SteppingPiece

  def moves
    castle_moves = ChessUtil::get_castle_moves(self);
    super.concat(castle_moves)
  end

  def movements
    [:nw, :ne, :sw, :se, :up, :down, :left, :right]
  end

  def to_s
    (color == :white) ? "\u2654" : "\u265A"
  end
end
