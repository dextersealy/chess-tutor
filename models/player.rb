class Player

  def initialize(game, color = nil)
    @game = game
    @color = color || game.current_player
  end

  def get_valid_moves(player_color = self.color)
    board.reduce(Hash.new) do |accumulator, piece|
      next accumulator unless piece.color == player_color
      accumulator[piece.current_pos] = piece.valid_moves
      accumulator
    end
  end

  def get_threats
    board.reduce(Hash.new) do |accumulator, piece|
      next accumulator unless piece.color == color
      threats = board.get_threats(piece.current_pos)
      next accumulator if threats.empty?
      accumulator[piece.current_pos] = threats.map { |t| t.current_pos }
      accumulator
    end
  end

  protected
  attr_reader :game, :color

  def board
    game.board
  end
end
