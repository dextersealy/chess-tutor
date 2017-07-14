require_relative '../lib/controller_base'
require_relative '../models/game'
require_relative '../models/player'
require_relative '../models/computer_player'
require_relative '../models/util'

class ChessController < ControllerBase
  protect_from_forgery
  after_action :save_game, except: [:show, :moves]

  def init
    @game = Game.new(session[:game_state])
    @board = game.board
  end

  def new
    @game = Game.new
    render json: get_board
  end

  def show
    @game = Game.new(session[:game_state])
    render json: get_board
  end

  def moves
    @game = Game.new(session[:game_state])
    render json: get_moves
  end

  def move
    @game = Game.new(session[:game_state])
    game.move(decode_pos(params[:from]), decode_pos(params[:to]))
    render json: get_board
  end

  def make_move
    @game = Game.new(session[:game_state])
    start_pos, end_pos = ComputerPlayer.new(game).get_move
    game.move(start_pos, end_pos) if start_pos && end_pos
    render json: { from: encode_pos(start_pos), to: encode_pos(end_pos),
      board: get_board }
  end

  private
  attr_accessor :game

  def board
    game.board
  end

  def save_game
    session[:game_state] = game.state
  end

  def get_board
    {
      captured: {
        game.current_player => game.captured(game.current_player).map(&:to_s),
        game.next_player => game.captured(game.next_player).map(&:to_s)
      },
      active: board.reduce(Hash.new) do |accumulator, piece|
        accumulator[encode_pos(piece.current_pos)] = piece.to_html
        accumulator
      end,
    }
  end

  def get_moves
    player = Player.new(game)
    player_moves = player.get_valid_moves
    threats = get_move_threats(player_moves).merge(player.get_threats)
    { player: encode_moves(player_moves), threats: encode_moves(threats) }
  end

  def get_move_threats(player_moves)
    result = Hash.new([])

    player_moves.each do |start_pos, moves|
      moves.each do |end_pos|
        board.get_move_threats(start_pos, end_pos).each do |piece|
          result[end_pos] += [piece.current_pos]
        end
      end
    end

    result
  end

  def encode_moves(moves)
    result = {}
    moves.each do |key, value|
      result[encode_pos(key)] = value.map { |pos| encode_pos(pos) }
    end
    result
  end
end
