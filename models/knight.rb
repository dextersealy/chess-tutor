require_relative 'piece.rb'
require_relative '../c/chess_util'

class Knight < Piece
  def moves
    ChessUtil::get_knight_moves(self)
  end

  def to_s
    (color == :white) ? "\u2658" : "\u265E"
  end
end
