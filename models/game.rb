require_relative 'board.rb'
require_relative 'cursor.rb'
require_relative 'display.rb'
require_relative 'player.rb'

class Game
  attr_accessor :board, :player1, :player2, :display

   def initialize
     @board = Board.new
     @current_player = :white
     @display = Display.new(@board)
     @player1 = Player.new(@board, @display, :white)
     @player2 = Player.new(@board, @display, :black)
   end

   def reset
     @board = Board.new
     @current_player = :white
   end

   def run
     until over?
       @player1.play_turn
       break if over?
       @player2.play_turn
     end
     display.render
     puts "Checkmate!"
     puts "#{winner.color} wins!"

   end

   def winner
     return player1 if board.checkmate?(:black)
     return player2 if board.checkmate?(:white)
     nil
   end

   def over?
    board.checkmate?(:white) || board.checkmate?(:black)
   end

   def move(from, to)
     board.move_piece(from, to)
     @current_player = next_player
   end

   def next_player
     { white: :black, black: :white }[@current_player]
   end

   def moveable
     pieces = @board.get_pieces(@current_player)
     pieces = pieces.reject { |piece| piece.valid_moves.empty? }
     pieces.map { |piece| board.coordinate_from_pos(piece.current_pos) }
  end

end

if __FILE__ == $PROGRAM_NAME

  g = Game.new
  g.run

end
