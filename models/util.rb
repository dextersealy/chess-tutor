require_relative 'null'

def encode_piece(piece)
  return ' ' if piece.nil?
  letter = (piece.class.name == 'Knight') ? 'N' : piece.class.name.first
  (piece.color == :white) ? letter.downcase : letter
end

def decode_piece(letter, pos)
  classname = case letter
  when 'p', 'P'
    'Pawn'
  when 'n', 'N'
    'Knight'
  when 'b', 'B'
    'Bishop'
  when 'r', 'R'
    'Rook'
  when 'q', 'Q'
    'Queen'
  when 'k', 'K'
    'King'
  else ' '
    nil
  end
  color = (letter == letter.upcase) ? :black : :white
  make_piece(classname, color, pos)
end

def encode_pos(pos)
  row, col = pos
  "abcdefgh"[col] + "87654321"[row]
end

def decode_pos(coord)
  col = "abcdefgh".index(coord[0])
  row = "87654321".index(coord[1])
  [row, col]
end

def make_piece(classname, color, pos = nil)
  return NullPiece.instance unless classname
  piece = Object.const_get(classname).new(self, color.to_sym)
  piece.current_pos = pos if pos
  piece
end
