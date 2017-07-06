require_relative 'piece.rb'

module SteppingPiece

  def moves
    result = []

    dirs = move_dirs
    dirs.each do |dir|
      result.concat(get_moves(dir, current_pos))
    end

    result
  end

  def get_moves(dir, pos)
    possible_moves = []
    pos = delta_sum(pos, Piece::MOVES[dir])
    valid_pos?(pos) ? possible_moves << pos : possible_moves
  end

end
