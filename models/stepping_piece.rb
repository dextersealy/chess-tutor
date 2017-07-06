require_relative 'piece.rb'

module SteppingPiece
  def get_moves(direction, pos)
    pos = add(pos, Piece::MOVES[direction])
    valid_pos?(pos) ? [pos] : []
  end
end
