class NullPiece < Piece
  include Singleton

  def initialize
    super(nil, nil)
  end
  def to_s
    " "
  end
end
