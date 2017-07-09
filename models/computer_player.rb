require_relative 'player'

class ComputerPlayer < Player
  def get_move
    calculate_move
  end

  private

  def calculate_move
    best_move, best_value = minmax(3)
    puts "#{encode(*best_move)} => #{best_value}"
    best_move
  end

  def minmax(max_depth, depth = 0, alpha = -100000, beta = 100000,
    maximizing = true, prefix = "")

    player = maximizing ? self.color : opposite(self.color)
    return nil, board_value if depth >= max_depth

    best_move = nil;
    best_value = maximizing ? -99999 : 99999

    each_move(player) do |move|
      board.move_piece(*move)
      _, value = minmax(max_depth, depth + 1, alpha, beta, !maximizing,
        prefix + "#{encode(*move)}, ")
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

      if beta <= alpha
        puts "pruned!!"
        break
      end
    end

    if best_move && best_value != 0 && depth < 2
      puts "#{prefix}#{encode(*best_move)} => #{best_value}"
    end

    return best_move, best_value
  end

  def encode(start_pos, end_pos)
    axis = ["87654321", "ABCDEFGH"]
    from = axis.zip(start_pos).map { |letters, idx| letters[idx] }.reverse.join
    to = axis.zip(end_pos).map { |letters, idx| letters[idx] }.reverse.join
    "#{from} => #{to}"
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
      100
    when 'Knight', 'Bishop'
      300
    when 'Rook'
      500
    when 'Queen'
      900
    when 'King'
      9000
    end
    value += location_value_of(piece)
    (self.color == piece.color) ? value : -value
  end

  def location_value_of(piece)
    row, col = piece.current_pos
    table = PIECE_TABLES[piece.class.name]
    table = table.reverse if piece.color == :black
    table[row][col]
  end

  PIECE_TABLES = {
    'Pawn' => [
      [0,   0,  0,  0,  0,  0,  0,  0],
      [50, 50, 50, 50, 50, 50, 50, 50],
      [10, 10, 20, 30, 30, 20, 10, 10],
      [0,   0,  0, 20, 20,  0,  0,  0],
      [5,   5, 10, 25, 25, 10,  5,  5],
      [5,  -5,-10,  0,  0,-10, -5,  5],
      [5,  10, 10,-20,-20, 10, 10,  5],
      [0,   0,  0,  0,  0,  0,  0,  0]
    ],
    'Knight' => [
      [-50,-40,-30,-30,-30,-30,-40,-50],
      [-40,-20,  0,  0,  0,  0,-20,-40],
      [-30,  0, 10, 15, 15, 10,  0,-30],
      [-30,  5, 15, 20, 20, 15,  5,-30],
      [-30,  0, 15, 20, 20, 15,  0,-30],
      [-30,  5, 10, 15, 15, 10,  5,-30],
      [-40,-20,  0,  5,  5,  0,-20,-40],
      [-50,-40,-30,-30,-30,-30,-40,-50]
    ],
    'Bishop' => [
      [-20,-10,-10,-10,-10,-10,-10,-20],
      [-10,  0,  0,  0,  0,  0,  0,-10],
      [-10,  0,  5, 10, 10,  5,  0,-10],
      [-10,  5,  5, 10, 10,  5,  5,-10],
      [-10,  0, 10, 10, 10, 10,  0,-10],
      [-10, 10, 10, 10, 10, 10, 10,-10],
      [-10,  5,  0,  0,  0,  0,  5,-10],
      [-20,-10,-10,-10,-10,-10,-10,-20]
    ],
    'Rook' => [
      [ 0,  0,  0,  0,  0,  0,  0,  0],
      [ 5, 10, 10, 10, 10, 10, 10,  5],
      [-5,  0,  0,  0,  0,  0,  0, -5],
      [-5,  0,  0,  0,  0,  0,  0, -5],
      [-5,  0,  0,  0,  0,  0,  0, -5],
      [-5,  0,  0,  0,  0,  0,  0, -5],
      [-5,  0,  0,  0,  0,  0,  0, -5],
      [ 0,  0,  0,  5,  5,  0,  0,  0]
    ],
    'Queen' => [
      [-20,-10,-10, -5, -5,-10,-10,-20],
      [-10,  0,  0,  0,  0,  0,  0,-10],
      [-10,  0,  5,  5,  5,  5,  0,-10],
      [ -5,  0,  5,  5,  5,  5,  0, -5],
      [  0,  0,  5,  5,  5,  5,  0, -5],
      [-10,  5,  5,  5,  5,  5,  0,-10],
      [-10,  0,  5,  0,  0,  0,  0,-10],
      [-20,-10,-10, -5, -5,-10,-10,-20]
    ],
    'King' => [
      [-30,-40,-40,-50,-50,-40,-40,-30],
      [-30,-40,-40,-50,-50,-40,-40,-30],
      [-30,-40,-40,-50,-50,-40,-40,-30],
      [-30,-40,-40,-50,-50,-40,-40,-30],
      [-20,-30,-30,-40,-40,-30,-30,-20],
      [-10,-20,-20,-20,-20,-20,-20,-10],
      [ 20, 20,  0,  0,  0,  0, 20, 20],
      [ 20, 30, 10,  0,  0, 10, 30, 20]
    ]
  }

end
