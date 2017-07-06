require 'colorize'
require_relative 'cursor.rb'

class Display
  attr_accessor :board, :cursor

  def initialize(board)
    @board = board
    @cursor = Cursor.new([0,0], @board)
  end

  def render
    system('clear')
    colors = { background: nil, color: nil }
    8.times do |row|
      back_color = row.even? ? :light_black : :green
      8.times do |col|
        piece = board[[row, col]]
        colors[:background] = back_color
        colors[:color] = piece.color
        if cursor.cursor_pos == [row, col]
          colors[:background], colors[:color] = colors[:color], colors[:background]
        end
        print piece.to_s.colorize(colors)
        back_color =  (back_color == :light_black) ? :green : :light_black
      end
    puts
    end
  end

  def get_input
    cursor.get_input(self)
  end
end
