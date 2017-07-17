require 'byebug'
require_relative '../models/board.rb'

describe 'Board' do
  let(:board) { Board.new }

  def move(board, *moves)
    (0...moves.length).step(2) do |i|
      from, to = moves[i], moves[i + 1]
      board.move_piece(decode_pos(from.to_s), decode_pos(to.to_s))
    end
  end

  def get(board, loc)
    piece = board[decode_pos(loc.to_s)]
    return nil if piece.nil?
    piece.to_s
  end

  def chomp_undo(str)
    str.split("|")[0...-1].join("|")
  end

  describe '#initialize' do
    it "sets up starting board" do
      initial_state = "RNBQKBNR/PPPPPPPP/8/8/8/8/pppppppp/rnbqkbnr|QKqk|"
      expect(board.state).to eq(initial_state)
    end

    it "restores previous state" do
      state = "RNBQKBNR/PPPPPPPP/8/8/8/6p1/pppppp1p/rnbqkbnr|QKqk|"
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

  describe "move_piece" do
    it "raises an error when the position is not valid" do
      expect { board.move_piece([8, 1], [7,  2]) }.to raise_error(InvalidPosition)
      expect { board.move_piece([0, 0], [1, -1]) }.to raise_error(InvalidPosition)
    end

    it "raises an error when no piece is present" do
      expect { move(board, :c3, :b1)}.to raise_error(NoPiece)
    end

    it "updates the board" do
      expect(get(board, :b1)).to eq("♘")
      move(board, :b1, :c3)
      expect(get(board, :b1)).to eq(nil)
      expect(get(board, :c3)).to eq("♘")
    end

    it "updates the piece" do
      piece = board[decode_pos(:b1)]
      expect(encode_pos(piece.current_pos).to_sym).to eq(:b1)
      move(board, :b1, :c3)
      expect(encode_pos(piece.current_pos).to_sym).to eq(:c3)
    end

    it "updates the state" do
      move(board, :b7, :b6, :c2, :c3, :b8, :c6)
      expect(chomp_undo(board.state)).to eq("R1BQKBNR/P1PPPPPP/1PN5/8/8/2p5/pp1ppppp/rnbqkbnr|QKqk")
    end

    it "removes captured pieces from the board" do
      expect(board.count { |piece| piece.is_a?(Pawn) }).to eq(16)
      move(board, :b1, :c3, :d7, :d5, :c3, :d5)
      expect(board.count { |piece| piece.is_a?(Pawn) }).to eq(15)
    end

    context "castleing" do
      it "castles kingside" do
        board = Board.new("R3K2R/8/8/8/8/8/8/r3k2r|QKqk|")
        move(board, :e1, :g1)
        expect(chomp_undo(board.state)).to eq("R3K2R/8/8/8/8/8/8/r4rk1|QK")
      end
      it "castles queenside" do
        board = Board.new("R3K2R/8/8/8/8/8/8/r3k2r|QKqk|")
        move(board, :e1, :c1)
        expect(chomp_undo(board.state)).to eq("R3K2R/8/8/8/8/8/8/2kr3r|QK")
      end
      it "cannot castle after rook is moved" do
        board = Board.new("R3K2R/8/8/8/8/8/8/r3k2r|QKqk|")
        expect(board[decode_pos("e1")].valid_moves).to include(decode_pos("c1"))
        expect(board[decode_pos("e1")].valid_moves).to include(decode_pos("g1"))
        move(board, :a1, :a2, :a2, :a1)
        expect(board[decode_pos("e1")].valid_moves).not_to include(decode_pos("c1"))
        expect(board[decode_pos("e1")].valid_moves).to include(decode_pos("g1"))
        move(board, :h1, :g1, :g1, :h1)
        expect(board[decode_pos("e1")].valid_moves).not_to include(decode_pos("g1"))
      end

      it "cannot castle after king is moved" do
        board = Board.new("R3K2R/8/8/8/8/8/8/r3k2r|QKqk|")
        expect(board[decode_pos("e1")].valid_moves).to include(decode_pos("c1"))
        expect(board[decode_pos("e1")].valid_moves).to include(decode_pos("g1"))
        move(board, :e1, :e2, :e2, :e1)
        expect(board[decode_pos("e1")].valid_moves).not_to include(decode_pos("c1"))
        expect(board[decode_pos("e1")].valid_moves).not_to include(decode_pos("g1"))
      end
    end

    context "promotion" do
      it "promotes pawn to queen" do
        board = Board.new("4K3/1p6/8/8/8/8/6P1/4k3||")
        move(board, :b7, :b8, :g2, :g1)
        expect(get(board, :b8)).to eq("♕")
        expect(get(board, :g1)).to eq("♛")
      end
    end
  end

  describe "undo_move" do
    it "does nothing on startup" do
      initial_state = board.state
      board.undo_move
      expect(board.state).to eq(initial_state)
    end

    it "reverses the last move" do
      initial_state = board.state
      move(board, :g8, :h6)
      expect(board.state).not_to eq(initial_state)
      board.undo_move
      expect(board.state).to eq(initial_state)
    end

    it "reverses multiple moves" do
      initial_state = board.state
      moves = [:b7, :b6, :c2, :c3, :b8, :c6]
      (0...moves.length).step(2) do |i|
        prev_state = board.state
        move(board, *moves[i, 2])
        expect(board.state).not_to eq(prev_state)
      end
      (moves.length / 2).times { board.undo_move }
      expect(board.state).to eq(initial_state)
    end

    it "reverses castling" do
      initial_state = "R3K2R/8/8/8/8/8/8/r3k2r|QKqk|"
      board = Board.new(initial_state)
      move(board, :e1, :g1)
      expect(chomp_undo(board.state)).to eq("R3K2R/8/8/8/8/8/8/r4rk1|QK")
      board.undo_move
      expect(board.state).to eq(initial_state)
    end

    it "reverses pawn promotion" do
      initial_state = "4K3/1p6/8/8/8/8/6P1/4k3||"
      board = Board.new(initial_state)
      move(board, :b7, :b8, :g2, :g1)
      expect(get(board, :b8)).to eq("♕")
      expect(get(board, :g1)).to eq("♛")
      board.undo_move
      expect(get(board, :g2)).to eq("♟")
      board.undo_move
      expect(get(board, :b7)).to eq("♙")
      expect(board.state).to eq(initial_state)
    end
  end

  describe "captured" do
    it "starts off empty" do
      expect(board.captured).to eq([])
    end

    it "returns captured pieces" do
      move(board, :b1, :c3, :d7, :d5, :c3, :d5)
      expect(board.captured.map { |p| encode_piece(p) }).to eq(["P"])
    end
  end
end
