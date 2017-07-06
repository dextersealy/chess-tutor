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
    game.move(pos_from_coordinate(params[:from]),
      pos_from_coordinate(params[:to]))
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
      id = coordinate_from_pos(piece.current_pos)
      result[id] = piece.to_html
    end

    result
  end

  def get_moves
    { current: get_player_moves(game.current_player),
      next: get_player_moves(game.next_player) }
  end

  def get_player_moves(player)
    result = {}

    board.get_pieces(player).each do |piece|
      moves = get_piece_moves(piece)
      next if moves.empty?
      result[coordinate_from_pos(piece.current_pos)] = moves
    end

    result
  end

  def get_piece_moves(piece)
    piece.valid_moves.map { |pos| coordinate_from_pos(pos) }
  end

  def coordinate_from_pos(pos)
    row, col = pos
    "ABCDEFGH"[col] + "87654321"[row]
  end

  def pos_from_coordinate(coord)
    col = "ABCDEFGH".index(coord[0])
    row = "87654321".index(coord[1])
    [row, col]
  end

end
