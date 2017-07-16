require_relative 'piece.rb'

class Pawn < Piece
  def moves
    ChessUtil::get_pawn_moves(self)
  end

  def to_s
    (color == :white) ? "\u2659" : "\u265F"
  end
end
