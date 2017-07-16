require_relative '../models/util'
require_relative '../models/board'

describe "Util" do
  let(:board) { Board.new }

  describe "encode_piece" do
    it "encodes pieces" do
      encoded = board.map { |piece| encode_piece(piece) }.join
      expect(encoded).to eq("RNBQKBNRPPPPPPPPpppppppprnbqkbnr")
    end
  end

  describe "decode_piece" do
    it "decodes pieces" do
      encoded = "RNBQKBNRPPPPPPPPpppppppprnbqkbnr"
      decoded = encoded.chars.map { |ch| decode_piece(ch, [0, 0]) }.join
      expect(decoded).to eq(board.to_a.join)
    end
  end

  describe "encode_pos" do
    it "encodes positions" do
      encoded = (0..7).map do |row|
        (0..7).map do |col|
          encode_pos([row, col])
        end.join
      end.join
      expected = "87654321".chars.map do |row|
        "abcdefgh".chars.map do |col|
          col + row
        end.join
      end.join
      expect(encoded).to eq(expected)
    end
  end

  describe "decode_pos" do
    it "decodes positions" do
      positions = diagonal_moves(4, 4).concat(straight_line_moves(4, 4))
      positions.each do |pos|
        expect(decode_pos(encode_pos(pos))).to eq(pos)
      end
    end
  end

end
