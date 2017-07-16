class Piece
  attr_accessor :color, :current_pos, :board

  def initialize(board, color = :white)
    @board = board
    @color = color
    @current_pos = nil
  end

  def valid_moves
    result = moves
    result.select! { |pos| valid_move?(pos) }
    result
  end

  def nil?
    false
  end

  def inspect
    "#{self.to_s}"
  end

  protected

  def valid_move?(end_pos)
    board.move_piece(current_pos, end_pos)
    result = !board.in_check?(color)
    board.undo_move
    result
  end
end
