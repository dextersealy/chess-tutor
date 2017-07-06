require_relative 'piece.rb'

class Knight < Piece

  def moves
    possible_moves = []

    KNIGHT_MOVES.each do |delta|
      pos = add(current_pos, delta)
      possible_moves << pos if valid_pos?(pos)
    end

    possible_moves
  end

  def to_s
    (color == :white) ? "\u2658" : "\u265E"
  end

  private

  KNIGHT_MOVES = [
    [-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]
  ]

end
