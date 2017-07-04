require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'
require_relative './flash'

class ControllerBase
  attr_reader :req, :res, :params

  def initialize(req, res, route_params = {})
    @req, @res = req, res
    @params = route_params.merge(req.params)
  end

  # Use ERB and binding to render templates

  def render(template_name)
    snake_case_class_name = self.class.to_s.underscore
    template_path = "views/#{snake_case_class_name}/#{template_name}.html.erb"

    template = File.read(template_path)
    html = ERB.new(template).result(binding)

    render_content(html, 'text/html')
  end

  # Redirect to specified URL

  def redirect_to(url)
    raise 'cannot render or redirect more that once' if already_built_response?
    @already_built_response = true

    session.store_session(res)
    flash.store_flash(res)

    res['Location'] = url
    res.status = 302
  end

  # Render a response. Raises an error if the caller tries to double
  # render or redirect.

  def render_content(content, content_type)
    raise 'cannot render or redirect more that once' if already_built_response?
    @already_built_response = true

    session.store_session(res)
    flash.store_flash(res)

    res['Content-Type'] = content_type
    res.write(content)
  end

  # Did we already render or redirect?

  def already_built_response?
    @already_built_response ||= false
  end

  # Retrieve current Session object

  def session
    @session ||= Session.new(@req)
  end

  # Retrieve current Flash object

  def flash
    @flash ||= Flash.new(@req)
  end

  # Invoke controller actions (e.g., :index, :show, :create)

  def invoke_action(name)
    if (protect_from_forgery? && @req.request_method != 'GET')
      check_authenticity_token
    else
      form_authenticity_token
    end

    send(name)
    render(name) unless already_built_response?
  end

  #  CSRF protection

  def self.protect_from_forgery
    @@protect_from_forgery = true;
  end

  def check_authenticity_token
    cookie = @req.cookies['authenticity_token']
    raise 'Invalid authenticity token' unless
      cookie && cookie == params['authenticity_token']
  end

  def form_authenticity_token
    @token ||= generate_authenticity_token
    @res.set_cookie('authenticity_token', value: @token, path: '/')
    @token
  end

  def generate_authenticity_token
    SecureRandom.urlsafe_base64(16)
  end

  def protect_from_forgery?
    @@protect_from_forgery
  end

  private

  @@protect_from_forgery = false
  
end
