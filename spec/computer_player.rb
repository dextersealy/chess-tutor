require_relative '../models/game.rb'
require_relative '../models/computer_player.rb'
require_relative '../models/util.rb'
require_relative 'spec_helper.rb'

require 'byebug'

describe 'ComputerPlayer' do

  # Execute a sequence of moves; input of array of even length
  # where the nth value is the starting position and nth+1 value
  # if the ending position

  def move(game, *moves)
    (0...moves.length).step(2) do |i|
      from, to = moves[i], moves[i + 1]
      game.move(decode_pos(from.to_s), decode_pos(to.to_s))
    end
  end

  def encode_move(move)
    move.map { |el| encode_pos(el).to_sym }
  end

  describe "#get_move" do
    it "makes a move" do
      game = Game.new
      move(game, :g2, :g3)
      expect(encode_move(ComputerPlayer.new(game).get_move)).to eq([:b8, :c6])
    end

    context "imminent checkmate" do
      it "makes a move" do
        game = Game.new(nil, Board.new("1r4K1/P2R1PPP/8/2P5/2p2p2/2b5/p1p3pp/6k1||"), :black)
        ai_move = encode_move(ComputerPlayer.new(game).get_move(verbose: false))
        expect(ai_move).to eq([:d7, :d8])
      end
    end

    context "checkmate" do
      it "returns nil" do
        game = Game.new(nil, Board.new("R1Bq2K1/PPP2PPP/2N5/31pQ2/8/1pn2n1p/p1p2pp1/3rr1k1||"), :black)
        ai_move = encode_move(ComputerPlayer.new(game).get_move(verbose: false))
        expect(ai_move).to eq([:c6, :d8])
        move(game, *ai_move, :d1, :d8)
        ai_move = ComputerPlayer.new(game).get_move(verbose: false)
        expect(ai_move).to eq(nil)
      end
    end
  end

end
