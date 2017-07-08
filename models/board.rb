require_relative 'piece.rb'
require_relative 'rook.rb'
require_relative 'knight.rb'
require_relative 'king.rb'
require_relative 'queen.rb'
require_relative 'pawn.rb'
require_relative 'bishop.rb'
require_relative 'null.rb'
require_relative 'errors.rb'

require 'byebug'

# comment

class Board
  include Enumerable

  attr_accessor :grid

  PIECES = [
    'Rook', 'Knight', 'Bishop', 'Queen', 'King', 'Bishop', 'Knight','Rook'
  ]

  def initialize(prev_state = nil)
    restore_state(prev_state) if prev_state
    return if @grid && @grid.flatten.length == 64;

    @undo = nil
    @grid = []

    grid << make_pieces(PIECES, :black, 0)
    grid << make_pieces(['Pawn'] * 8, :black, 1)

    4.times { @grid << Array.new(8) { NullPiece.instance } }

    grid << make_pieces(['Pawn'] * 8, :white, 6)
    grid << make_pieces(PIECES, :white, 7)
  end

  def move_piece(start_pos, end_pos)
    raise InvalidPosition.new unless [start_pos, end_pos].all? { |pos| in_bounds?(pos) }
    raise NoPiece.new if self[start_pos].is_a?(NullPiece)

    @undo = [start_pos, end_pos, self[end_pos]]

    piece = self[start_pos]
    self[end_pos] = piece
    piece.current_pos = end_pos

    self[start_pos] = NullPiece.instance
  end

  def undo_move
    return unless @undo
    start_pos, end_pos, piece = @undo
    self[start_pos] = self[end_pos]
    self[start_pos].current_pos = start_pos
    self[end_pos] = piece
    self[end_pos].current_pos = end_pos
    @undo = nil
  end

  def [](pos)
    row, col = pos
    grid[row][col]
  end

  def []=(pos, piece)
    row, col = pos
    grid[row][col] = piece
  end

  def in_bounds?(pos)
    pos.all? { |coord| coord.between?(0, 7) }
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
    return true if get_pieces(color).all? { |piece| piece.valid_moves.empty? }
    false
  end

  def get_pieces(color)
    select { |piece| piece.color == color }
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

  private

  def find_king(color)
    find { |piece| piece.is_a?(King) && piece.color == color }.current_pos
    raise "should never get here"
  end

  def can_any_piece_move_to?(pos)
    any? { |piece| piece.moves.include?(pos) }
  end

  def restore_state(state)
    return if state.empty?

    @grid = []
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
