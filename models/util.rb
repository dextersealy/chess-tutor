require_relative 'null.rb'

def make_piece(classname, color, pos = nil)
  return NullPiece.instance unless classname
  piece = Object.const_get(classname).new(self, color.to_sym)
  piece.current_pos = pos if pos
  piece
end

def encode_pieces(pieces)
  arr = []
  pieces.each_with_index do |piece, idx|
    arr << '/' if idx % 8 == 0 && idx != 0
    if piece.nil?
      (arr.last.is_a? Numeric) ? arr[arr.size-1] += 1 : arr << 1
    else
      arr << encode_piece(piece)
    end
  end
  arr.join
end

def decode_pieces(str)
  idx = 0;
  arr = [NullPiece.instance] * 64;
  str.each_char do |ch|
    next if ch == '/'
    if "12345678".include?(ch)
      idx += ch.to_i
    else
      arr[idx] = decode_piece(ch, [idx / 8, idx % 8])
      idx += 1
    end
  end
  arr
end

def encode_piece(piece)
  return nil if piece.nil?
  letter = (piece.class.name == 'Knight') ? 'N' : piece.class.name[0]
  (piece.color == :white) ? letter.downcase : letter
end

def decode_piece(letter, pos)
  return NullPiece.instance unless letter
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
  pos ? 'abcdefgh'[col] + '87654321'[row] : ''
end

def decode_pos(loc)
  col = 'abcdefgh'.index(loc[0])
  row = '87654321'.index(loc[1])
  [row, col]
end

def encode_castleable(arr)
  return nil if arr.nil? || arr.empty?
  arr.map do |pos|
    case pos
    when [0, 0]
      'Q'
    when [0, 7]
      'K'
    when [7, 0]
      'q'
    when [7, 7]
      'k'
    end
  end.join
end

def decode_castleable(str)
  return nil if str.nil? || str.length == 0 || str == '-'
  str.each_char.map do |letter|
    case letter
    when 'Q'
      [0, 0]
    when 'K'
      [0, 7]
    when 'q'
      [7, 0]
    when 'k'
      [7, 7]
    end
  end
end
