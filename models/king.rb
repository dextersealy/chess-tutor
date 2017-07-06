require_relative 'piece.rb'
require_relative 'stepping_piece.rb'

class King < Piece
  include SteppingPiece

  def movements
    [:nw, :ne, :sw, :se, :up, :down, :left, :right]
  end

  def to_s
    (color == :white) ? "\u2654" : "\u265A"
  end
end
