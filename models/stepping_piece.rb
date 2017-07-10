require_relative 'piece.rb'
require_relative '../c/chess_util'

module SteppingPiece
  def get_moves(direction, pos)
    pos = ChessUtil::add(pos, Piece::MOVES[direction])
    valid_pos?(pos) ? [pos] : []
  end
end
