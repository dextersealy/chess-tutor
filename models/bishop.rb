require_relative 'piece.rb'
require_relative 'sliding_piece.rb'

class Bishop < Piece
  include SlidingPiece

  def to_s
    (color == :white) ? "\u2657" : "\u265D"
  end

  protected

  def movements
    [:nw, :ne, :sw, :se]
  end
end
