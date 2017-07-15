require_relative 'piece.rb'
require_relative '../c/chess_util'

module SlidingPiece
  def moves
    ChessUtil::get_moves(self, movements, :slide)
  end
end
