require_relative 'piece.rb'
require_relative '../c/chess_util'

module SteppingPiece
  def moves
    ChessUtil::get_moves(self, movements, :step)
  end
end
