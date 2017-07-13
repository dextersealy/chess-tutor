require_relative 'piece'
require_relative 'rook'
require_relative 'knight'
require_relative 'king'
require_relative 'queen'
require_relative 'pawn'
require_relative 'bishop'
require_relative 'null'
require_relative 'errors'
require_relative 'util'
require_relative '../c/chess_util'

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
      @undo = []
    end
  end

  def [](pos)
    row, col = pos
    board[row * 8 + col]
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
    valid = !in_check?(color)
    undo_move
    valid
  end

  def move_piece(start_pos, end_pos)
    raise InvalidPosition.new unless start_pos.is_a?(Array) &&
      ChessUtil::in_bounds(start_pos) && end_pos.is_a?(Array) &&
      ChessUtil::in_bounds(end_pos)

    raise NoPiece.new if self[start_pos].is_a?(NullPiece)

    @undo << [start_pos, end_pos, self[end_pos]]

    piece = self[start_pos]
    self[end_pos] = piece
    piece.current_pos = end_pos

    self[start_pos] = NullPiece.instance
  end

  def undo_move
    return if @undo.empty?
    start_pos, end_pos, piece = @undo.pop
    self[start_pos] = self[end_pos]
    self[start_pos].current_pos = start_pos
    self[end_pos] = piece
    self[end_pos].current_pos = end_pos
  end

  def captured
    @undo.map { |_, _, piece|  piece }.reject { |piece| piece.nil? }
  end

  def in_check?(color)
    can_any_piece_move_to? king_pos_of color
  end

  def checkmate?(color)
    return false unless in_check?(color)
    all? { |piece| piece.color != color || piece.valid_moves.empty? }
  end

  def get_threats(pos)
    select { |piece| piece.valid_moves.include?(pos) }
  end

  def get_move_threats(start_pos, end_pos)
    move_piece(start_pos, end_pos)
    threats = select { |piece| piece.moves.include?(end_pos) }
    undo_move
    threats
  end

  def save_state
    encode
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
    row, col = pos
    board[row * 8 + col] = piece
  end

  def make_pieces(factory_array, color, row)
    factory_array.map.with_index do |class_, idx|
      make_piece(class_, color, [row, idx])
    end
  end

  def king_pos_of(color)
    return find { |piece| piece.is_a?(King) && piece.color == color }.current_pos
  end

  def can_any_piece_move_to?(pos)
    any? { |piece| piece.moves.include?(pos) }
  end

  def restore_state(str)
    return false unless str
    decode(str)
    true
  end

  def encode
    arr = []
    # Pieces
    board.each_with_index do |piece, idx|
      arr << '/' if idx % 8 == 0 && idx != 0
      if piece.nil?
        (arr.last.is_a? Numeric) ? arr[arr.size-1] += 1 : arr << 1
      else
        arr << encode_piece(piece)
      end
    end

    # Undo
    arr << '|'
    @undo.each do |from, to, piece|
      arr << "#{encode_pos(from)}#{encode_pos(to)}#{encode_piece(piece)}"
    end

    arr.join
  end

  def decode(str)
    pieces, undo = str.split('|')

    idx = 0;
    @board = [NullPiece.instance] * 64;
    pieces.each_char do |ch|
      next if ch == '/'
      if "12345678".include?(ch)
        idx += ch.to_i
      else
        @board[idx] = decode_piece(ch, [idx / 8, idx % 8])
        idx += 1
      end
    end

    @undo = []
    return unless undo
    (0...undo.length).step(5) do |i|
      start_pos = decode_pos(undo.slice(i, 2))
      end_pos = decode_pos(undo.slice(i + 2, 2))
      piece = decode_piece(undo[i+4], end_pos)
      @undo << [start_pos, end_pos, piece]
    end
  end

end
