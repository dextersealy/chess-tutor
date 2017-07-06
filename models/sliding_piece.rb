require_relative 'piece.rb'

module SlidingPiece

  def moves
    dirs = move_dirs
    result = []
    dirs.each do |dir|
      result.concat(get_moves(dir, current_pos))
    end
    result
  end

  def get_moves(dir, pos)
    possible_moves = []

    while true
      pos = delta_sum(pos, Piece::MOVES[dir])
      break unless valid_pos?(pos)
      possible_moves << pos
      break if board.occupied?(pos)
    end

    possible_moves
  end

end
