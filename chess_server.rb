require 'rack'
require 'optparse'
require_relative 'controllers/chess_controller'
require_relative 'lib/router'
require_relative 'lib/static'

router = Router.new
router.draw do
  get Regexp.new("^/$"), ChessController, :init
  post Regexp.new("^/new$"), ChessController, :new
  get Regexp.new("^/show$"), ChessController, :show
  get Regexp.new("^/moves$"), ChessController, :moves
  post Regexp.new("^/move$"), ChessController, :move
  get Regexp.new("^/move$"), ChessController, :make_move
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

app = Rack::Builder.new do
  use Static
  run app
end.to_app

options = {}
OptionParser.new do |opts|
  opts.on("-pPORT") do |port|
    options[:port] = port
  end
end.parse!

Rack::Server.start(app: app, Port: options[:port] || 3000)
