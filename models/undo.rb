require_relative 'util.rb'

class Undo
  def initialize(board, prev_state = nil)
    @board = board
    @moves = restore(prev_state) || []
  end

  def push(piece, from, to, castleable)
    captured = @board[to]
    if (to.first % 7) == 0 && piece.is_a?(Pawn)
      @moves << [from, to, captured, nil, piece]
    elsif piece.is_a?(Rook) || piece.is_a?(King)
      @moves << [from, to, captured, castleable.dup]
    elsif captured.nil?
      @moves << [from, to]
    else
      @moves << [from, to, captured]
    end
  end

  def pop
    @moves.pop
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

  def encode(from, to, piece = nil, castleable = nil, promoted = nil)
    promoted = encode_piece(promoted)
    castleable = encode_castleable(castleable)
    piece = encode_piece(piece)
    castleable ||= '-' if promoted
    piece ||= ' ' if castleable
    "#{encode_pos(from)}#{encode_pos(to)}#{piece}#{castleable}#{promoted}"
  end

  def decode(str)
    from = decode_pos(str[0..1])
    to = decode_pos(str[2..3])
    piece = decode_piece(str[4], to)
    if str[5] == '-'
      promoted = decode_piece(str[6])
      castleable = nil
    else
      promoted = nil
      castleable = decode_castleable(str[5..-1])
    end

    if promoted
      [from, to, piece, castleable, promoted]
    elsif castleable
      [from, to, piece, castleable]
    elsif piece
      [from, to, piece]
    else
      [from, to]
    end
  end
end
