class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method.to_s.upcase
    @controller_class = controller_class
    @action_name = action_name.to_s
  end

  # Check if request path and method matches route

  def matches?(req)
    req.request_method == @http_method && req.path =~ @pattern
  end

  # Extract route params, instantiate controller, and invoke action

  def run(req, res, options = {})
    m = req.path.match(@pattern)
    route_params = m.names.zip(m.captures).to_h.merge(options)

    controller = controller_class.new(req, res, route_params)
    controller.invoke_action(@action_name)
  end
end
