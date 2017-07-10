require 'inline'
require_relative 'piece.rb'
require_relative 'rook.rb'
require_relative 'knight.rb'
require_relative 'king.rb'
require_relative 'queen.rb'
require_relative 'pawn.rb'
require_relative 'bishop.rb'
require_relative 'null.rb'
require_relative 'errors.rb'

class Board
  include Enumerable

  PIECES = [
    'Rook', 'Knight', 'Bishop', 'Queen', 'King', 'Bishop', 'Knight','Rook'
  ]

  def initialize(prev_state = nil)
    @undo = []
    @grid = []

    restore_state(prev_state) if prev_state
    return if @grid && @grid.flatten.length == 64;

    grid << make_pieces(PIECES, :black, 0)
    grid << make_pieces(['Pawn'] * 8, :black, 1)
    4.times { @grid << Array.new(8) { NullPiece.instance } }
    grid << make_pieces(['Pawn'] * 8, :white, 6)
    grid << make_pieces(PIECES, :white, 7)
  end

  def move_piece(start_pos, end_pos)
    raise InvalidPosition.new unless [start_pos, end_pos].all? { |pos| in_bounds_c(pos) }
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

  def [](pos)
    row, col = pos
    grid[row][col]
  end

  def []=(pos, piece)
    row, col = pos
    grid[row][col] = piece
  end

  inline do |builder|
    builder.c "
      VALUE in_bounds_c(VALUE pos) {
        int row = NUM2INT(rb_ary_entry(pos, 0));
        int col = NUM2INT(rb_ary_entry(pos, 1));
        if (row >= 0 && row < 8 && col >= 0 && col < 8) {
          return Qtrue;
        } else {
          return Qfalse;
        }
      }"
  end

  def occupied?(pos)
    !self[pos].is_a?(NullPiece)
  end

  def in_check?(color)
    pos = find_king(color)
    can_any_piece_move_to?(pos)
  end

  def checkmate?(color)
    return false unless in_check?(color)
    all? { |piece| piece.color != color || piece.valid_moves.empty? }
  end

  def each
    grid.each do |row|
      row.each do |piece|
        yield piece unless piece.nil?
      end
    end
  end

  def save_state
    map { |piece| [piece.class.name, piece.color, piece.current_pos] }
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

  def valid_move?(start_pos, end_pos)
    color = self[start_pos].color
    move_piece(start_pos, end_pos)
    valid = !in_check?(color)
    undo_move
    valid
  end

  def to_s
    grid.map { |row| row.join('') }.join("\n")
  end

  def inspect
    "#{to_s}"
  end

  private
  attr_accessor :grid

  def find_king(color)
    return find { |piece| piece.is_a?(King) && piece.color == color }.current_pos
  end

  def can_any_piece_move_to?(pos)
    any? { |piece| piece.moves.include?(pos) }
  end

  def restore_state(state)
    return if state.empty?

    8.times { @grid << Array.new(8) { NullPiece.instance } }

    state.each do |item|
      piece = make_piece(*item)
      self[piece.current_pos] = piece
    end
  end

  def make_pieces(factory_array, color, row)
    factory_array.map.with_index do |class_, idx|
      make_piece(class_, color, [row, idx])
    end
  end

  def make_piece(classname, color, pos)
    piece = Object.const_get(classname).new(self, color.to_sym)
    piece.current_pos = pos
    piece
  end
end
