require 'byebug'
require_relative '../lib/controller_base'
require_relative '../models/game'

class ChessController < ControllerBase
  protect_from_forgery
  before_action :load_game, except: [:new]
  after_action :save_game, only: [:move, :new]

  def index
    @board = game.board
  end

  def new
    render json: get_board
  end

  def moves
    render json: get_moves
  end

  def move
    game.move(decode(params[:from]), decode(params[:to]))
    render json: get_moves
  end

  private

  def game
    @game ||= Game.new
  end

  def board
    game.board
  end

  def load_game
    @game ||= Game.new(session[:game_state])
  end

  def save_game
    session[:game_state] = game.save_state
  end

  def get_board
    result = {}

    pieces = board.get_pieces(:white).concat(board.get_pieces(:black))
    pieces.each do |piece|
      id = encode(piece.current_pos)
      result[id] = piece.to_html
    end

    result
  end

  def get_moves
    player_moves = get_player_moves
    threats = get_threats(player_moves)
    { player: encode_moves(player_moves), threats: encode_moves(threats) }
  end

  def get_player_moves
    pieces = board.get_pieces(game.current_player)
    result = pieces.reduce(Hash.new([])) do |accumulator, piece|
      accumulator[piece.current_pos] = piece.valid_moves
      accumulator
    end
    result.reject { |k, v| v.empty? }
  end

  def encode_moves(moves)
    result = Hash.new([])
    moves.each do |key, value|
      result[encode(key)] = value.map { |pos| encode(pos) }
    end
    result
  end

  def get_threats(player_moves)
    result = Hash.new([])

    player_moves.each do |start_pos, moves|
      moves.map do |end_pos|
        threats = board.get_threats(start_pos, end_pos)
        threats.each do |piece|
          result[end_pos] += [piece.current_pos]
        end
      end
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
