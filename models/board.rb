require_relative 'piece.rb'
require_relative 'rook.rb'
require_relative 'knight.rb'
require_relative 'king.rb'
require_relative 'queen.rb'
require_relative 'pawn.rb'
require_relative 'bishop.rb'
require_relative 'null.rb'
require_relative 'errors.rb'
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

  def []=(pos, piece)
    row, col = pos
    board[row * 8 + col] = piece
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
    raise InvalidPosition.new unless ChessUtil::in_bounds(start_pos) &&
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
    {
      pieces: map { |piece| [piece.class.name, piece.color, piece.current_pos] },
      undo: @undo.map do |start_pos, end_pos, piece|
        [start_pos, end_pos, piece.nil? ? nil : piece.class.name, piece.color]
      end
    }
  end

  def to_s
    (0..7).map { |row| board.slice(row * 8, 8).join('') }.join("\n")
  end

  def inspect
    "#{to_s}"
  end

  private
  attr_accessor :board

  def king_pos_of(color)
    return find { |piece| piece.is_a?(King) && piece.color == color }.current_pos
  end

  def can_any_piece_move_to?(pos)
    any? { |piece| piece.moves.include?(pos) }
  end

  def restore_state(state)
    return false unless state

    @board = [NullPiece.instance] * 64;
    state['pieces'].each do |item|
      piece = make_piece(*item)
      self[piece.current_pos] = piece
    end

    @undo = []
    state['undo'].each do |start_pos, end_pos, classname, color|
      @undo << [start_pos, end_pos, make_piece(classname, color, end_pos)]
    end

    true
  end

  def make_pieces(factory_array, color, row)
    factory_array.map.with_index do |class_, idx|
      make_piece(class_, color, [row, idx])
    end
  end

  def make_piece(classname, color, pos)
    return NullPiece.instance unless classname
    piece = Object.const_get(classname).new(self, color.to_sym)
    piece.current_pos = pos
    piece
  end
end
