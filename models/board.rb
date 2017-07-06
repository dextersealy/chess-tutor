
require_relative 'piece.rb'
require_relative 'display.rb'
require_relative 'rook.rb'
require_relative 'knight.rb'
require_relative 'king.rb'
require_relative 'queen.rb'
require_relative 'pawn.rb'
require_relative 'bishop.rb'
require_relative 'errors.rb'

require 'byebug'

# comment

class Board
  attr_accessor :grid

  PIECES = [
    'Rook', 'Knight', 'Bishop', 'Queen', 'King', 'Bishop', 'Knight','Rook'
  ]

  def initialize(prev_state = nil)
    restore_state(prev_state) if prev_state
    return if @grid && @grid.flatten.length == 64;

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

    piece = self[start_pos]
    self[end_pos] = piece
    piece.current_pos = end_pos

    self[start_pos] = NullPiece.instance
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
    grid.flatten.select { |piece| piece.color == color }
  end

  def save_state
    pieces = get_pieces(:white).concat(get_pieces(:black))
    pieces.map { |piece| [piece.class.name, piece.color, piece.current_pos] }
  end

  private

  def find_king(color)
    grid.flatten.each do |piece|
      return piece.current_pos if piece.is_a?(King) && piece.color == color
    end
    raise "should never get here"
  end

  def can_any_piece_move_to?(pos)
    grid.flatten.each do |piece|
      return true if piece.moves.include?(pos)
    end
    false
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
      make_piece(class_, color.to_sym, [row, idx])
    end
  end

  def make_piece(classname, color, pos)
    piece = Object.const_get(classname).new(self, color.to_sym)
    piece.current_pos = pos
    piece
  end
end
