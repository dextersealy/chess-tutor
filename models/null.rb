require 'singleton'

class NullPiece < Piece
  include Singleton

  def initialize
    super(nil, nil)
  end

  def movements
    []
  end

  def to_s
    " "
  end

  def nil?
    true
  end
end
