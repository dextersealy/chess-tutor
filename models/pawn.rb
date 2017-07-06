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
     result = super

     possible_moves = []
     if color == :black
       [:sw, :se].map { |dir| possible_moves.concat(get_moves(dir, current_pos)) }
       if current_pos.first == 1
         result << add(current_pos, [2, 0])
       end
     else
       [:nw, :ne].map { |dir| possible_moves.concat(get_moves(dir, current_pos)) }
       if current_pos.first == 6
         result << add(current_pos, [-2, 0])
       end
     end
     result.concat(possible_moves.select { |pos| board.occupied?(pos) })
  end
end
