require_relative 'board.rb'

class Game
  attr_accessor :board, :current_player

  def initialize(prev_state = {})
    if prev_state && prev_state['V'] == VERSION
      @board = Board.new(prev_state['B'])
      @current_player = prev_state['P'].to_sym
    else
      @board = Board.new
      @current_player = :white
    end
  end

  def move(from, to)
    board.move_piece(from, to)
    @current_player = next_player
  end

  def captured(player)
    board.captured.select { |piece| piece.color == player }
  end

  def over?
    board.checkmate?(:white) || board.checkmate?(:black)
  end

  def winner
    return :black if board.checkmate?(:black)
    return :white if board.checkmate?(:white)
    nil
  end

  def state
    { 'V' => VERSION, 'B' => @board.state, 'P' => current_player }
  end

  def next_player
    { white: :black, black: :white }[@current_player]
  end

  def inspect
    "player: #{current_player}\n#{board}"
  end

  private

  VERSION = 4
end
