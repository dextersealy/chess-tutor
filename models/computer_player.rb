require_relative 'player'
require_relative 'util'
require_relative '../c/chess_util'

class ComputerPlayer < Player
  def get_move
    calculate_move
  end

  private

  def calculate_move
    t1 = Time.now
    @move_count = 0
    best_move, _ = minmax(3)
    puts "examined #{@move_count} moves in #{'%.02f' % (Time.now - t1)}s"
    best_move
  end

  def minmax(max_depth, depth = 0, alpha = -100000, beta = 100000,
    maximizing = true, prefix = "")
    return nil, board_value if depth >= max_depth

    best_move = nil;
    best_value = maximizing ? -99999 : 99999
    player = maximizing ? self.color : opposite(self.color)

    each_move(player) do |move|
      board.move_piece(*move)
      @move_count += 1
      _, value = minmax(max_depth, depth + 1, alpha, beta, !maximizing)
        # prefix + "#{encode(*move)}, ")
      board.undo_move

      if maximizing
        best_move = move if value > best_value
        best_value = value if value > best_value
        alpha = best_value if best_value > alpha
      else
        best_move = move if value < best_value
        best_value = value if value < best_value
        beta = best_value if beta < best_value
      end

      break if beta <= alpha
    end

    # if best_move && best_value != 0 && depth < 2
    #   puts "#{prefix}#{encode(*best_move)} => #{best_value}"
    # end

    return best_move, best_value
  end

  def each_move(color, &block)
    moves = valid_moves(color).reject { |_, v| v.empty? }
    moves.each do |start_pos, ends|
      ends.each do |end_pos|
        block.call([start_pos, end_pos])
      end
    end
  end

  def board_value
    ChessUtil::get_board_value(board, self.color)
  end

  def opposite(color)
    color == :black ? :white : :black
  end

  def encode(start_pos, end_pos)
    "#{encode_pos(start_pos)} => #{encode_pos(end_pos)}"
  end
end
