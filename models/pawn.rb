require_relative 'piece.rb'
require_relative 'stepping_piece.rb'

class Pawn < Piece
  include SteppingPiece

  def movements
    [(color == :black) ? :down : :up]
  end

  def to_s
    (color == :white) ? "\u2659" : "\u265F"
  end

  def moves
    step_moves + capture_moves
  end

  private

  def step_moves
    result = []

    dir = (color == :black) ? :down : :up
    pos = current_pos
    2.times do
      pos = add(pos, Piece::MOVES[dir])
      break if board.occupied?(pos) || !board.in_bounds_c(pos)
      result << pos
      break unless first_move?
    end

    result
  end

  def capture_moves
    dirs = (color == :black) ? [:sw, :se] : [:nw, :ne]
    result = dirs.reduce([]) { |arr, dir| arr.concat(get_moves(dir, current_pos)) }
    result.select { |pos| board.occupied?(pos) }
  end

  def first_move?
    ((color == :black) && current_pos.first == 1) ||
    ((color == :white) && current_pos.first == 6)
  end

end
