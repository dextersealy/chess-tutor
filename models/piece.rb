require 'singleton'
require 'htmlentities'
require_relative '../c/chess_util'

class Piece
  attr_accessor :color, :current_pos, :board, :moved

  def initialize(board, color = :white)
    @board = board
    @color = color
    @current_pos = nil
    @moved = false;
  end

  def valid_moves
    moves.select { |pos| board.valid_move?(current_pos, pos) }
  end

  def nil?
    false
  end

  def to_html
    HTMLEntities.new.encode(self.to_s, :decimal)
  end

  def inspect
    "#{self.to_s}"
  end
end
