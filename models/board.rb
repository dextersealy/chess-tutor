require_relative 'bishop.rb'
require_relative 'errors.rb'
require_relative 'king.rb'
require_relative 'knight.rb'
require_relative 'null.rb'
require_relative 'pawn.rb'
require_relative 'piece.rb'
require_relative 'rook.rb'
require_relative 'queen.rb'
require_relative 'undo.rb'
require_relative 'util.rb'
require_relative '../c/chess_util'

class Board
  include Enumerable
  attr_accessor :castleable

  def initialize(prev_state = nil)
    return if restore(prev_state)
    @board = []
    @board.concat(make_pieces(PIECES, :black, 0))
    @board.concat(make_pieces(['Pawn'] * 8, :black, 1))
    @board.concat([NullPiece.instance] * 32)
    @board.concat(make_pieces(['Pawn'] * 8, :white, 6))
    @board.concat(make_pieces(PIECES, :white, 7))
    @castleable = [[0, 0], [0,7], [7, 0], [7, 7]]
    @undo = Undo.new(self)
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

  def move_piece(start_pos, end_pos)
    unless ChessUtil::in_bounds(start_pos) && ChessUtil::in_bounds(end_pos)
      raise InvalidPosition.new
    end
    raise NoPiece.new if self[start_pos].is_a?(NullPiece)

    piece = self[start_pos]
    castle(start_pos, end_pos) if castling(piece, start_pos, end_pos)
    @undo.push(piece, start_pos, end_pos, @castleable)

    if promoting(piece, end_pos)
      piece = make_piece("Queen", piece.color)
    elsif piece.is_a?(Rook)
      @castleable.reject! { |pos| pos == start_pos }
    elsif piece.is_a?(King)
      @castleable.reject! { |pos| pos[0] == start_pos[0] }
    end

    self[end_pos] = piece
    piece.current_pos = end_pos
    self[start_pos] = NullPiece.instance
  end

  def undo_move
    start_pos, end_pos, captured, castleable, piece = @undo.pop
    return unless end_pos

    piece ||= self[end_pos]
    self[start_pos] = piece
    piece.current_pos = start_pos

    captured ||= NullPiece.instance
    self[end_pos] = captured
    captured.current_pos = end_pos

    @castleable = castleable if castleable
    undo_move if castling(piece, start_pos, end_pos)
  end

  def captured
    @undo.captured
  end

  def in_check?(color)
    can_any_piece_move_to? king_of(color).current_pos
  end

  def checkmate?(color)
    in_check?(color) && all? { |p| p.color != color || p.valid_moves.empty? }
  end

  def state
    "#{encode_pieces(@board)}" \
    "|#{encode_castleable(@castleable)}" \
    "|#{@undo.save}"
  end

  def to_s
    (0..7).map { |row| board[row * 8, 8].join }.join("\n")
  end

  def inspect
    "#{to_s}"
  end

  private
  attr_accessor :board

  PIECES = [
    'Rook', 'Knight', 'Bishop', 'Queen', 'King', 'Bishop', 'Knight','Rook'
  ]

  def make_pieces(factory_array, color, row)
    factory_array.map.with_index do |class_, idx|
      make_piece(class_, color, [row, idx])
    end
  end

  def []=(pos, piece)
    ChessUtil::set_piece_at(@board, pos, piece)
  end

  def king_of(color)
    find { |piece| piece.is_a?(King) && piece.color == color }
  end

  def can_any_piece_move_to?(pos)
    any? { |piece| ChessUtil::moves_include(piece.moves, pos) }
  end

  def promoting(piece, end_pos)
    (end_pos.first % 7) == 0 && piece.is_a?(Pawn)
  end

  def castling(piece, start_pos, end_pos)
    piece.is_a?(King) && (end_pos.last - start_pos.last).abs == 2
  end

  def castle(start_pos, end_pos)
    row, end_col = end_pos
    if (end_col > start_pos.last)
      move_piece([row, 7], [row, end_col - 1])
    else
      move_piece([row, 0], [row, end_col + 1])
    end
  end

  def restore(str)
    return false unless str && str.length > 0
    pieces, castleable, undo = str.split('|', -1)
    @board = decode_pieces(pieces)
    @castleable = decode_castleable(castleable) || []
    @undo = Undo.new(self, undo)
    true
  end
end
