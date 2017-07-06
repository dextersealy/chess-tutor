require 'byebug'

class Player

  attr_accessor :board, :display, :color

  def initialize(board, display, color)
    @board = board
    @display = display
    @color = color
  end

  def play_turn
    begin
      start_pos = display.get_input
      piece = board[start_pos]
      raise InvalidMove.new unless piece.color == color

      end_pos = display.get_input
      raise InvalidMove.new unless piece.valid_moves.include?(end_pos)

      board.move_piece(start_pos, end_pos)
    rescue InvalidMove
      puts "Not a valid move!"
      sleep(1)
      retry
    end

  end

end
