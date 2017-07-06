require_relative 'piece.rb'
require_relative 'sliding_piece.rb'

class Bishop < Piece
  include SlidingPiece

  def move_dirs
    [:nw, :ne, :sw, :se]
  end

  def to_s
    (color == :white) ? "\u2657" : "\u265D"
  end
end
