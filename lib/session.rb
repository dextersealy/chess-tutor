require 'json'

# Session object is used to maintain state across HTTP requests

class Session

  def initialize(req)
    json_data = req.cookies[COOKIE_NAME]
    @session_cookies = json_data ? JSON.parse(json_data) : Hash.new
  end

  def [](key)
    @session_cookies[key.to_s]
  end

  def []=(key, val)
    @session_cookies[key.to_s] = val
  end

  def store_session(res)
    res.set_cookie(COOKIE_NAME, {
      path: '/', value: @session_cookies.to_json
    })
  end

  private

  COOKIE_NAME = '_tracks_app'
end
