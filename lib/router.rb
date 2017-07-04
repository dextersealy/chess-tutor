require_relative './route'

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # Run the route matching the request. Returns 404 if no match is found.

  def run(req, res)
    route = match(req)
    if route
      route.run(req, res)
    else
      res.status = 404
      res.write("page #{req.path} not found")
      res.finish
    end
  end

  # Find route that matche request

  def match(req)
    routes.find { |route| route.matches?(req) }
  end

  # Add route

  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # Convenience methods for declaring routes

  def draw(&proc)
    instance_eval(&proc)
  end

  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

end
