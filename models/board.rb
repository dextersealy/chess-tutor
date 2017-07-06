
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
    Object.const_get('Rook'),
    Object.const_get('Knight'),
    Object.const_get('Bishop'),
    Object.const_get('Queen'),
    Object.const_get('King'),
    Object.const_get('Bishop'),
    Object.const_get('Knight'),
    Object.const_get('Rook')
  ]

  def initialize
    @grid = []
    grid << make_pieces(PIECES, :black, 0)
    grid << make_pieces([Object.const_get('Pawn')] * 8, :black, 1)

    4.times { @grid << Array.new(8) { NullPiece.instance } }

    grid << make_pieces([Object.const_get('Pawn')] * 8, :white, 6)
    grid << make_pieces(PIECES, :white, 7)
  end

  def make_pieces(factory_array, color, row)
    factory_array.map.with_index do |factory, idx|
      piece = factory.new(self, color)
      piece.current_pos = [row, idx]
      piece
    end
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
    pos.all? { |coord| coord.between?(0,7) }
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

  def coordinate_from_pos(pos)
    row, col = pos
    "ABCDEFGH"[col] + "87654321"[row]
  end

  def pos_from_coordinate(coord)
    col = "ABCDEFGH".index(coord[0])
    row = "87654321".index(coord[1])
    [row, col]
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

end
