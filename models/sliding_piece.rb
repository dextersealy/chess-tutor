require_relative 'piece.rb'
require_relative '../c/chess_util'

module SlidingPiece
  def get_moves(dir, pos)
    possible_moves = []

    while true
      pos = ChessUtil::add(pos, Piece::MOVES[dir])
      break unless valid_pos?(pos)
      possible_moves << pos
      break if board.occupied?(pos)
    end

    possible_moves
  end

end
