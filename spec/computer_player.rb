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

    it "makes a final move" do
      board = Board.new("1r4K1/P2R1PPP/8/2P5/2p2p2/2b5/p1p3pp/6k1||")
      game = Game.new(nil, board)
      move(game, :b8, :a8)
      move = ComputerPlayer.new(game).get_move
      p move
    end
  end

end
