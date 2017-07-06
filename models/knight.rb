require_relative 'piece.rb'

class Knight < Piece

  def moves
    knight_moves = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1]
    ]

    possible_moves = []
    knight_moves.each do |delta|
      pos = delta_sum(current_pos, delta)
      possible_moves << pos if valid_pos?(pos)
    end
    possible_moves
  end

  def to_s
    (color == :white) ? "\u2658" : "\u265E"
  end

end
