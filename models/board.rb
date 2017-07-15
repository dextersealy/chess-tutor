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

    @undo << [start_pos, end_pos, self[end_pos], piece.moved]
    self[end_pos] = piece
    piece.current_pos = end_pos
    self[start_pos] = NullPiece.instance
  end

  def undo_move
    return if @undo.empty?
    start_pos, end_pos, captured, moved_state = @undo.pop

    piece = self[end_pos]
    self[start_pos] = piece
    piece.current_pos = start_pos
    piece.moved = moved_state

    self[end_pos] = captured
    captured.current_pos = end_pos

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
