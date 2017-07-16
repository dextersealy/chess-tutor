require_relative '../models/board.rb'
require_relative 'spec_helper.rb'

describe "Piece" do
  let(:board) { Board.new }

  describe "nil?" do
    it "returns false for occupied squares" do
      (0..7).each { |idx| expect(board[[0, idx]].nil?).to be(false) }
      (0..7).each { |idx| expect(board[[1, idx]].nil?).to be(false) }
      (0..7).each { |idx| expect(board[[6, idx]].nil?).to be(false) }
      (0..7).each { |idx| expect(board[[7, idx]].nil?).to be(false) }
    end

    it "returns true for empty squares" do
      (0..7).each { |idx| expect(board[[2, idx]].nil?).to be(true) }
      (0..7).each { |idx| expect(board[[3, idx]].nil?).to be(true) }
      (0..7).each { |idx| expect(board[[4, idx]].nil?).to be(true) }
      (0..7).each { |idx| expect(board[[5, idx]].nil?).to be(true) }
    end
  end

  describe "moves" do
    context "null piece" do
      it "has no moves" do
        expect(board[[2, 0]].valid_moves).to eq([])
      end
    end

    context "pawn" do
      it "has two moves when on home row" do
        expect(board[[1, 0]].moves).to match_array([[2, 0], [3, 0]])
        expect(board[[6, 0]].moves).to match_array([[5, 0], [4, 0]])
      end
      it "has one move when off home row" do
        board = Board.new("4K3/8/P7/8/8/p7/8/4k3||")
        expect(board[[2, 0]].moves).to match_array([[3, 0]])
        expect(board[[5, 0]].moves).to match_array([[4, 0]])
      end
      it "cannot capture forward" do
        board = Board.new("4K3/8/P7/p7/8/8/8/4k3||")
        expect(board[[2, 0]].moves).to match_array([])
        expect(board[[3, 0]].moves).to match_array([])
      end
      it "can capture diagonally" do
        board = Board.new("4K3/8/P7/1p6/8/8/8/4k3||")
        expect(board[[2, 0]].moves).to match_array([[3, 0], [3, 1]])
        expect(board[[3, 1]].moves).to match_array([[2, 0], [2, 1]])
      end
    end

    context "rook" do
      it "can move horizontally and vertically" do
        board = Board.new("4K3/8/8/3R4/8/5r2/8/4k3||")
        expect(board[[3, 3]].moves).to match_array(straight_line_moves(3, 3))
        expect(board[[5, 5]].moves).to match_array(straight_line_moves(5, 5))
      end
    end

    context "bishop" do
      it "can move diagonally" do
        board = Board.new("4K3/8/8/3B4/3b4/8/8/4k3||")
        expect(board[[3, 3]].moves).to match_array(diagonal_moves(3, 3))
        expect(board[[4, 3]].moves).to match_array(diagonal_moves(4, 3))
      end
    end

    context "knight" do
      it "can do knight moves" do
        board = Board.new("4K3/8/8/3N4/4n3/8/8/4k3||")
        expect(board[[3, 3]].moves).to match_array([
          [1, 2], [1, 4], [2, 5], [4, 5], [5, 4], [5, 2], [4, 1], [2, 1]
        ])
        expect(board[[4, 4]].moves).to match_array([
          [2, 3], [2, 5], [3, 6], [5, 6], [6, 5], [6, 3], [5, 2], [3, 2]
        ])
      end
    end

    context "queen" do
      it "can move horizontally, vertically and diagonally" do
        board = Board.new("4K3/8/3Q4/8/8/5q2/8/4k3||")
        expect(board[[2, 3]].moves).to match_array(
          straight_line_moves(2, 3).concat(diagonal_moves(2, 3)))
        expect(board[[5, 5]].moves).to match_array(
          straight_line_moves(5, 5).concat(diagonal_moves(5, 5)))
      end
    end

    context "king" do
      it "can move one step in any direction" do
        board = Board.new("8/4K3/8/8/8/8/4k3/8||")
        expect(board[[1, 4]].moves).to match_array(single_step_moves(1, 4))
        expect(board[[6, 4]].moves).to match_array(single_step_moves(6, 4))
      end
      it "can castle kingside and queenside" do
        board = Board.new("R3K2R/8/8/8/8/8/8/r3k2r|QKqk|")
        expect(board[[0, 4]].moves).to match_array(
          single_step_moves(0, 4).concat([[0, 2], [0, 6]]))
        expect(board[[7, 4]].moves).to match_array(
          single_step_moves(7, 4).concat([[7, 2], [7, 6]]))
      end
    end
end

  describe "valid_moves" do
    it "cannot leave king in check" do
      board = Board.new("RNBQKBNR/PPP1PPPP/3p4/8/q7/8/8/4k3||")
      expect(board[[0, 2]].valid_moves).to match_array([[1, 3]])
      expect(board[[0, 3]].valid_moves).to match_array([[1, 3]])
    end

    it "cannot put king check" do
      board = Board.new("4K3/5N2/8/7q/8/8/8/4k3||")
      expect(board[[1, 5]].valid_moves).to eq([])
      board = Board.new("4K3/5B2/8/7q/8/8/8/4k3||")
      expect(board[[1, 5]].valid_moves).to eq([[2, 6], [3, 7]])
      board = Board.new("4K3/5P2/8/7q/8/8/8/4k3||")
      expect(board[[1, 5]].valid_moves).to eq([])
    end

    context "king" do
      it "cannot move into check" do
        board = Board.new("4K3/8/7q/8/8/8/Q7/4k3||")
        expect(board[[0, 4]].valid_moves).to match_array(
          single_step_moves(0, 4).reject { |pos| pos == [0, 5] })
        expect(board[[7, 4]].valid_moves).to match_array(
          single_step_moves(7, 4).reject { |pos| pos[0] == 6 })
      end
      it "cannot castle when in check" do
        board = Board.new("R3K2R/8/8/4q3/4Q3/8/8/r3k2r|QKqk|")
        expect(board[[0, 4]].valid_moves).to match_array(
          single_step_moves(0, 4).reject { |pos| pos == [1, 4] })
        expect(board[[7, 4]].valid_moves).to match_array(
          single_step_moves(7, 4).reject { |pos| pos == [6, 4] })
      end
      it "cannot castle through check" do
        board = Board.new("R3K2R/8/7q/8/Q7/8/8/r3k2r|QKqk|")
        expect(board[[0, 4]].valid_moves).to match_array(
          single_step_moves(0, 4).concat([[0, 2]]).reject { |pos| pos == [0, 5] })
        expect(board[[7, 4]].valid_moves).to match_array(
          single_step_moves(7, 4).concat([[7, 6]]).reject { |pos| pos == [7, 3] })
      end
    end
  end
end
