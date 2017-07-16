require_relative '../models/board.rb'

describe 'Board' do
  let(:board) { Board.new }

  describe '#initialize' do
    it "sets up starting board" do
      game_start = "RNBQKBNR/PPPPPPPP/8/8/8/8/pppppppp/rnbqkbnr|qkQK|"
      expect(board.state).to eq(game_start)
    end

    it "restores previous state" do
      state = "RNBQKBNR/PPPPPPPP/8/8/8/6p1/pppppp1p/rnbqkbnr|qkQK|"
      board = Board.new(state)
      expect(board.state).to eq(state)
    end
  end

  describe '[]' do
    it "returns pieces on the board" do
      expect((0..7).map { |idx| board[[0, idx]] }.join).to eq("♜♞♝♛♚♝♞♜")
      expect((0..7).map { |idx| board[[1, idx]] }.join).to eq("♟♟♟♟♟♟♟♟")
      expect((0..7).map { |idx| board[[2, idx]] }.join).to eq("        ")
      expect((0..7).map { |idx| board[[3, idx]] }.join).to eq("        ")
      expect((0..7).map { |idx| board[[4, idx]] }.join).to eq("        ")
      expect((0..7).map { |idx| board[[5, idx]] }.join).to eq("        ")
      expect((0..7).map { |idx| board[[6, idx]] }.join).to eq("♙♙♙♙♙♙♙♙")
      expect((0..7).map { |idx| board[[7, idx]] }.join).to eq("♖♘♗♕♔♗♘♖")
    end

    it "returns nil for invalid positions" do
      invalid = [[-1, 0], [8, 0], [0, -1], [0, 8], [-1, -1], [8, 8]]
      invalid.each { |pos| expect(board[pos]).to eq(nil) }
    end
  end

  describe 'each' do
    it "yields the pieces on the board" do
      pieces = []
      board.each { |piece| pieces << piece }
      expect(pieces.join).to eq("♜♞♝♛♚♝♞♜♟♟♟♟♟♟♟♟♙♙♙♙♙♙♙♙♖♘♗♕♔♗♘♖")
    end
  end

  describe 'occupied?' do
    it "returns true when the position is occupied" do
      (0..7).each { |idx| expect(board.occupied?([0, idx])).to eq(true) }
      (0..7).each { |idx| expect(board.occupied?([1, idx])).to eq(true) }
      (0..7).each { |idx| expect(board.occupied?([6, idx])).to eq(true) }
      (0..7).each { |idx| expect(board.occupied?([7, idx])).to eq(true) }
    end

    it "returns false when the position is empty" do
      (0..7).each { |idx| expect(board.occupied?([2, idx])).to eq(false) }
      (0..7).each { |idx| expect(board.occupied?([3, idx])).to eq(false) }
      (0..7).each { |idx| expect(board.occupied?([4, idx])).to eq(false) }
      (0..7).each { |idx| expect(board.occupied?([5, idx])).to eq(false) }
    end
  end

end
