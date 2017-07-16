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
    if !restore_state(prev_state)
      @board = []
      @board.concat(make_pieces(PIECES, :black, 0))
      @board.concat(make_pieces(['Pawn'] * 8, :black, 1))
      @board.concat([NullPiece.instance] * 32)
      @board.concat(make_pieces(['Pawn'] * 8, :white, 6))
      @board.concat(make_pieces(PIECES, :white, 7))
      @castleable = [[0, 0], [0,7], [7, 0], [7, 7]]
      @undo = Undo.new(self)
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

  def move_piece(start_pos, end_pos)
    unless ChessUtil::in_bounds(start_pos) && ChessUtil::in_bounds(end_pos)
      raise InvalidPosition.new
    end
    raise NoPiece.new if self[start_pos].is_a?(NullPiece)

    moving = self[start_pos]
    castle(start_pos, end_pos) if castling(moving, start_pos, end_pos)

    @undo.push(start_pos, end_pos)

    self[end_pos] = moving
    moving.current_pos = end_pos
    self[start_pos] = NullPiece.instance

    if moving.is_a?(Rook)
      @castleable.reject! { |pos| pos == start_pos }
    elsif moving.is_a?(King)
      @castleable.reject! { |pos| pos[0] == start_pos[0] }
    end
  end

  def undo_move
    return if @undo.empty?
    start_pos, end_pos, captured, castleable = @undo.pop

    moved = self[end_pos]
    self[start_pos] = moved
    moved.current_pos = start_pos

    if captured
      self[end_pos] = captured
      captured.current_pos = end_pos
    else
      self[end_pos] = NullPiece.instance
    end

    @castleable = castleable if castleable
    undo_move if castling(moved, start_pos, end_pos)
  end

  def captured
    @undo.captured
  end

  def in_check?(color)
    can_any_piece_move_to? king_of(color).current_pos
  end

  def checkmate?(color)
    in_check?(color) && none? do |piece|
      piece.color == color && !piece.valid_moves.empty?
    end
  end

  def state
    "#{encode_pieces(@board)}" \
    "|#{encode_castleable(@castleable) || '-'}" \
    "|#{@undo.save}"
  end

  def to_s
    (0..7).map { |row| board.slice(row * 8, 8).join('') }.join("\n")
  end

  def inspect
    "#{to_s}"
  end

  private
  attr_accessor :board

  PIECES = [
    'Rook', 'Knight', 'Bishop', 'Queen', 'King', 'Bishop', 'Knight','Rook'
  ]

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
    @castleable = decode_castleable(castleable) || []
    @undo = Undo.new(self, undo)
    true
  end
end
