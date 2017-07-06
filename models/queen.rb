require_relative 'piece.rb'
require_relative 'sliding_piece.rb'

class Queen < Piece
  include SlidingPiece

  def movements
    [:nw, :ne, :sw, :se, :up, :down, :left, :right]
  end

  def to_s
    (color == :white) ? "\u2655" : "\u265B"
  end
end
