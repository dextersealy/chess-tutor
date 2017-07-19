require_relative '../c/chess_util'

class Player
  def initialize(game, color = nil)
    @game = game
    @color = color || game.current_player
  end

  def valid_moves(player_color = self.color)
    board.reduce(Hash.new) do |accumulator, piece|
      next accumulator unless piece.color == player_color
      accumulator[piece.current_pos] = piece.valid_moves
      accumulator
    end
  end

  def threats
    pieces = []
    opposing = board.reduce(Hash.new) do |hash, piece|
      pieces << piece if piece.color == color
      hash[piece] = piece.valid_moves unless piece.color == color
      hash
    end

    pieces.reduce(Hash.new) do |accumulator, piece|
      threats = opposing.select do |_ ,moves|
        ChessUtil::moves_include(moves, piece.current_pos)
      end.keys
      next accumulator if threats.empty?
      accumulator[piece.current_pos] = threats.map { |t| t.current_pos }
      accumulator
    end
  end

  def move_threats(start_pos, end_pos)
    board.move_piece(start_pos, end_pos)
    threats = board.select { |p| p.color != color && p.valid_moves.include?(end_pos) }
    board.undo_move
    threats
  end

  protected
  attr_reader :game, :color

  def board
    game.board
  end
end
