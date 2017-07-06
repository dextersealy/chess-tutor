require_relative 'piece.rb'

module SlidingPiece
  def get_moves(dir, pos)
    possible_moves = []

    while true
      pos = add(pos, Piece::MOVES[dir])
      break unless valid_pos?(pos)
      possible_moves << pos
      break if board.occupied?(pos)
    end

    possible_moves
  end

end
