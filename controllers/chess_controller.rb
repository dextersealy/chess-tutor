require 'byebug'
require_relative '../lib/controller_base'
require_relative '../models/game'

class ChessController < ControllerBase
  protect_from_forgery
  after_action :save_game, only: [:move, :new]

  attr_reader :game

  def show
    @game = Game.new(session[:game_state])
    @board = game.board
  end

  def new
    @game = Game.new
    render json: get_board
  end

  def moves
    @game = Game.new(session[:game_state])
    render json: get_moves
  end

  def move
    @game = Game.new(session[:game_state])
    game.move(decode(params[:from]), decode(params[:to]))
    render json: get_moves
  end

  private

  def board
    game.board
  end

  def save_game
    session[:game_state] = game.save_state
  end

  def get_board
    board.reduce(Hash.new) do |accumulator, piece|
      accumulator[encode(piece.current_pos)] = piece.to_html
      accumulator
    end
  end

  def get_moves
    player_moves = get_player_moves(game.current_player)
    threats = get_threats.merge(get_move_threats(player_moves))
    { player: encode_moves(player_moves), threats: encode_moves(threats) }
  end

  def get_player_moves(player)
    board.reduce(Hash.new) do |accumulator, piece|
      next accumulator unless piece.color == player
      accumulator[piece.current_pos] = piece.valid_moves
      accumulator
    end
  end

  def get_threats
    board.reduce(Hash.new) do |accumulator, piece|
      next accumulator unless piece.color == game.current_player
      threats = board.get_threats(piece.current_pos)
      next accumulator if threats.empty?
      accumulator[piece.current_pos] = threats.map { |t| t.current_pos }
      accumulator
    end
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
      result[encode(key)] = value.map { |pos| encode(pos) }
    end
    result
  end

  def encode(pos)
    row, col = pos
    "ABCDEFGH"[col] + "87654321"[row]
  end

  def decode(coord)
    col = "ABCDEFGH".index(coord[0])
    row = "87654321".index(coord[1])
    [row, col]
  end

end
