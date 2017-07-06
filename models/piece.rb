require 'colorize'
require 'singleton'
require 'htmlentities'

class Piece

  MOVES = {up: [-1, 0], down: [1, 0], right: [0, 1], left: [0, -1],
           nw: [-1, -1], ne: [-1, 1], sw: [1, -1], se: [1, 1] }

  attr_accessor :color, :current_pos, :board

  def initialize(board, color = :white)
    @color = color
    @board = board
    @current_pos = nil
  end

  def moves
    []
  end

  def valid_pos?(pos)
    return false unless board.in_bounds?(pos)
    board[pos].color != self.color
  end

  def to_html
    html = HTMLEntities.new.encode(self.to_s, :decimal)
    html
  end

  def inspect
    "#{self.to_s}"
  end

  def delta_sum(pos, delta)
    pos.zip(delta).map { |arr| arr.reduce(:+) }
  end

  def valid_moves
    original_pos = current_pos
    result = []
    begin
      moves.each do |pos|
        current_pos = pos
        result << pos unless board.in_check?(color)
      end
    ensure
      current_pos = original_pos
    end
    result
  end

end

class NullPiece < Piece
  include Singleton

  def initialize
    super(nil, nil)
  end
  def to_s
    " "
  end
end
