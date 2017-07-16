require_relative 'util.rb'

class Undo
  def initialize(board, prev_state = nil)
    @board = board
    @moves = restore(prev_state) || []
  end

  def push(from, to)
    moving, captured = @board[from], @board[to]
    if moving.is_a?(Rook) || moving.is_a?(King)
      @moves << [from, to, captured, @board.castleable.dup]
    elsif captured.nil?
      @moves << [from, to]
    else
      @moves << [from, to, captured]
    end
  end

  def pop
    @moves.pop
  end

  def empty?
    @moves.empty?
  end

  def captured
    @moves.map { |_, _, piece|  piece }.reject { |piece| piece.nil? }
  end

  def save
    @moves.map { |move| encode(*move) }.join(',')
  end

  private

  def restore(str)
    return nil unless str && str.length > 0
    str.split(',').map { |move| decode(move) }
  end

  def encode(from, to, piece = nil, castleable = nil)
    piece_code = encode_piece(piece)
    castleable_code = encode_castleable(castleable)
    piece_code = ' ' unless piece_code || castleable_code.nil?
    "#{encode_pos(from)}#{encode_pos(to)}#{piece_code}#{castleable_code}"
  end

  def decode(str)
    from = decode_pos(str[0..1])
    to = decode_pos(str[2..3])
    piece = decode_piece(str[4], to)
    castleable = decode_castleable(str[5..-1])
    if castleable.nil? && piece.nil?
      [from, to]
    elsif castleable.nil?
      [from, to, piece]
    else
      [from, to, piece, castleable]
    end
  end
end
