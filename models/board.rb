require_relative 'piece.rb'
require_relative 'rook.rb'
require_relative 'knight.rb'
require_relative 'king.rb'
require_relative 'queen.rb'
require_relative 'pawn.rb'
require_relative 'bishop.rb'
require_relative 'null.rb'
require_relative 'errors.rb'
require_relative 'util.rb'
require_relative '../c/chess_util'

require 'byebug'

class Board
  include Enumerable

  PIECES = [
    'Rook', 'Knight', 'Bishop', 'Queen', 'King', 'Bishop', 'Knight','Rook'
  ]

  def initialize(prev_state = nil)
    if !restore_state(prev_state)
      @board = []
      @board.concat(make_pieces(PIECES, :black, 0))
      @board.concat(make_pieces(['Pawn'] * 8, :black, 1))
      @board.concat([NullPiece.instance] * 32)
      @board.concat(make_pieces(['Pawn'] * 8, :white, 6))
      @board.concat(make_pieces(PIECES, :white, 7))
      @castleable = [[0, 0], [0,7], [7, 0], [7, 7]]
      @undo = []
    end
  end

  def [](pos)
    ChessUtil::get_piece_at(@board, pos)
  end

  def each
    board.each { |piece| yield piece unless piece.nil? }
  end

  def occupied?(pos)
    !self[pos].is_a?(NullPiece)
  end

  def valid_move?(start_pos, end_pos)
    color = self[start_pos].color
    move_piece(start_pos, end_pos)
    result = !in_check?(color)
    undo_move
    result
  end

  def move_piece(start_pos, end_pos)
    raise InvalidPosition.new unless ChessUtil::in_bounds(start_pos) &&
      ChessUtil::in_bounds(end_pos)
    raise NoPiece.new if self[start_pos].is_a?(NullPiece)

    piece = self[start_pos]
    castle(start_pos, end_pos) if castling(piece, start_pos, end_pos)

    if piece.is_a?(Rook)
      castleable = @castleable
      @castleable = @castleable.reject { |pos| pos == start_pos }
    elsif piece.is_a?(King)
      castleable = @castleable
      @castleable = @castleable.reject { |pos| pos[0] == start_pos[0] }
    else
      castleable = nil
    end
    @undo << [start_pos, end_pos, self[end_pos], castleable]

    self[end_pos] = piece
    piece.current_pos = end_pos
    self[start_pos] = NullPiece.instance
  end

  def undo_move
    return if @undo.empty?
    start_pos, end_pos, captured, castleable = @undo.pop

    piece = self[end_pos]
    self[start_pos] = piece
    piece.current_pos = start_pos

    self[end_pos] = captured
    captured.current_pos = end_pos

    @castleable = castleable if castleable
    undo_move if castling(piece, start_pos, end_pos)
  end

  def captured
    @undo.map { |_, _, piece|  piece }.reject { |piece| piece.nil? }
  end

  def in_check?(color)
    can_any_piece_move_to? king_of(color).current_pos
  end

  def checkmate?(color)
    in_check?(color) && none? do |piece|
      piece.color == color && !piece.valid_moves.empty?
    end
  end

  def threats(pos, player = self[pos].color)
    select { |piece| piece.color != player && piece.valid_moves.include?(pos) }
  end

  def move_threats(start_pos, end_pos)
    player = self[start_pos].color
    move_piece(start_pos, end_pos)
    result = threats(end_pos, player)
    undo_move
    result
  end

  def state
    "#{encode_pieces(@board)}" \
    "|#{encode_castleable(@castleable)}" \
    "|#{@undo.map { |undo| encode_undo(*undo) }.join(',')}"
  end

  def to_s
    (0..7).map { |row| board.slice(row * 8, 8).join('') }.join("\n")
  end

  def inspect
    "#{to_s}"
  end

  private
  attr_accessor :board

  def []=(pos, piece)
    ChessUtil::set_piece_at(@board, pos, piece)
  end

  def king_of(color)
    find { |piece| piece.is_a?(King) && piece.color == color }
  end

  def can_any_piece_move_to?(pos)
    any? { |piece| ChessUtil::moves_include(piece.moves, pos) }
  end

  def castling(piece, start_pos, end_pos)
    piece.is_a?(King) && (end_pos.last - start_pos.last).abs == 2
  end

  def castle(start_pos, end_pos)
    row, col = end_pos
    if (col > start_pos.last)
      start_pos = [row, 7]
      end_pos = [row, col - 1]
    else
      start_pos = [row, 0]
      end_pos = [row, col + 1]
    end
    move_piece(start_pos, end_pos)
  end

  def make_pieces(factory_array, color, row)
    factory_array.map.with_index do |class_, idx|
      make_piece(class_, color, [row, idx])
    end
  end

  def restore_state(str)
    return false unless str && str.length > 0
    pieces, castleable, undo = str.split('|', -1)
    @board = decode_pieces(pieces)
    @castleable = decode_castleable(castleable)
    @undo = undo.split(',').map { |str| decode_undo(str) }
    true
  end

  def encode_pieces(pieces)
    arr = []
    pieces.each_with_index do |piece, idx|
      arr << '/' if idx % 8 == 0 && idx != 0
      if piece.nil?
        (arr.last.is_a? Numeric) ? arr[arr.size-1] += 1 : arr << 1
      else
        arr << encode_piece(piece)
      end
    end
    arr.join
  end

  def decode_pieces(str)
    idx = 0;
    arr = [NullPiece.instance] * 64;
    str.each_char do |ch|
      next if ch == '/'
      if "12345678".include?(ch)
        idx += ch.to_i
      else
        arr[idx] = decode_piece(ch, [idx / 8, idx % 8])
        idx += 1
      end
    end
    arr
  end

  def encode_undo(from, to, piece, castleable)
    piece_code = encode_piece(piece)
    castleable_code = encode_castleable(castleable)
    piece_code = ' ' unless piece_code || castleable_code.nil?
    "#{encode_pos(from)}#{encode_pos(to)}#{piece_code}#{castleable_code}"
  end

  def decode_undo(str)
    from = decode_pos(str[0..1])
    to = decode_pos(str[2..3])
    piece = decode_piece(str[4], to)
    castleable = decode_castleable(str[5..-1])
    [from, to, piece, castleable]
  end

  def encode_castleable(arr)
    if arr.nil?
      nil
    elsif arr.empty?
      '-'
    else
      arr.map do |pos|
        case pos
        when [0, 0]
          'q'
        when [0, 7]
          'k'
        when [7, 0]
          'Q'
        when [7, 7]
          'K'
        end
      end.join
    end
  end

  def decode_castleable(str)
    if str.nil? || str.length == 0
      nil
    elsif str == '-'
      []
    else
      str.each_char.map do |letter|
        case letter
        when 'q'
          [0, 0]
        when 'k'
          [0, 7]
        when 'Q'
          [7, 0]
        when 'K'
          [7, 7]
        end
      end
    end
  end

end
