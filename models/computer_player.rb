require_relative 'player'

class ComputerPlayer < Player
  include Enumerable

  def get_move
    move = calculate_move
    puts "#{move}"
    move
  end

  private

  def calculate_move
    best_move, best_value = [nil, -9999]

    depth = 3
    maximizing = true

    each_move(self.color) do |move|
      board.move_piece(*move)
      value = minmax(depth - 1, -10000, 10000, !maximizing)
      puts "#{move}: #{value}"
      best_move, best_value = [move, value] if value > best_value
      board.undo_move
    end

    best_move
  end

  def minmax(depth, alpha, beta, maximizing)
    return (maximizing ? 1 : -1) * board_value if depth == 0

    best_value = maximizing ? -9999 : 9999
    each_move(maximizing ? self.color : opposite(self.color)) do |move|
      board.move_piece(*move)
      values = [best_value, minmax(depth - 1, alpha, beta, !maximizing)]
      best_value = maximizing ? values.max : values.min
      board.undo_move
      alpha = [best_value, alpha].max if maximizing
      beta = [best_value, beta].min unless maximizing
      break if beta <= alpha
    end

    return best_value
  end

  def opposite(color)
    color == :black ? :white : :black
  end

  def each_move(color, &block)
    moves = get_valid_moves(color).reject { |_, v| v.empty? }
    moves.each do |start_pos, ends|
      ends.each do |end_pos|
        block.call([start_pos, end_pos])
      end
    end
  end

  def board_value
    board.inject(0) { |sum, piece| sum + value_of(piece) }
  end

  def value_of(piece)
    value = case piece.class.name
    when 'Pawn'
      10
    when 'Knight', 'Bishop'
      30
    when 'Rook'
      50
    when 'Queen'
      90
    when 'King'
      900
    end
    piece.color == :white ? value : -value
  end

end
