require_relative 'piece.rb'
require_relative 'stepping_piece.rb'

class Pawn < Piece
  include SteppingPiece

  def move_dirs
    [(color == :black) ? :down : :up]
  end

  def to_s
    (color == :white) ? "\u2659" : "\u265F"
  end

  def moves
     result = SteppingPiece.instance_method(:moves).bind(self).call

     possible_moves = []
     if color == :black
       [:sw, :se].map { |dir| possible_moves.concat(get_moves(dir, current_pos)) }
       if current_pos.first == 1
         result << delta_sum(current_pos, [2, 0])
       end
     else
       [:nw, :ne].map { |dir| possible_moves.concat(get_moves(dir, current_pos)) }
       if current_pos.first == 6
         result << delta_sum(current_pos, [-2, 0])
       end
     end
     result.concat(possible_moves.select { |pos| board.occupied?(pos) })
  end
end
