require 'singleton'

class NullPiece < Piece
  include Singleton

  def initialize
    super(nil, nil)
  end

  def moves
    []
  end

  def nil?
    true
  end

  def to_s
    " "
  end
end
