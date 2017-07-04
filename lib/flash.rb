require 'json'

# The Flash maintains state that's cleared with each request.

class Flash

  def initialize(req)
    @curr_cycle_data = parse(req.cookies[COOKIE_NAME])
    @next_cycle_data = {}
  end

  def [](key)
    curr_cycle_data[key.to_s] || next_cycle_data[key.to_s]
  end

  def []=(key, val)
    next_cycle_data[key.to_s] = val
  end

  def now
    curr_cycle_data
  end

  def store_flash(res)
    res.set_cookie(COOKIE_NAME, {
      path: '/', value: next_cycle_data.to_json
    })
  end

  private

  def parse(json_data)
    return {} unless json_data
    JSON.parse(json_data).map { |k, v| [k.to_s, v] }.to_h
  end

  attr_accessor :curr_cycle_data, :next_cycle_data

  COOKIE_NAME = '_tracks_app_flash'
end
