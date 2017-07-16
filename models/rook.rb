require_relative 'piece.rb'
require_relative 'sliding_piece.rb'

class Rook < Piece
  include SlidingPiece

  def to_s
    (color == :white) ? "\u2656" : "\u265C"
  end

  protected

  def movements
    [:up, :down, :left, :right]
  end
end
