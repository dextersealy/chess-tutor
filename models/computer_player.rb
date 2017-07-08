require_relative 'player'

class ComputerPlayer < Player

  def get_move
    calculate_move
  end

  private

  def calculate_move
    moves = get_valid_moves.reject { |_, v| v.empty? }
    start_pos = moves.keys.sample
    [start_pos, moves[start_pos].sample]
  end

end
