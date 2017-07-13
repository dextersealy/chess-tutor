require_relative 'piece.rb'
require_relative '../c/chess_util'

module SlidingPiece
  def get_moves(dir, pos)
    ChessUtil::get_sliding_moves(pos, Piece::MOVES[dir], board)
  end
end
