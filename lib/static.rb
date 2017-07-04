require 'mime/types'

# This middelware serves static assets

class Static
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    path = match_static(req.path)
    return @app.call(env) unless path

    res = load_asset(path)
    res.finish
  end

  private

  def load_asset(path)
    res = Rack::Response.new
    if File.exist?(path)
      read_mime_content(res, path)
    else
      res.status = 404
      res.write("file not found")
    end
    res
  end

  def read_mime_content(res, path)
    ext = File.extname(path)
    res['Content-type'] = MIME::Types.type_for(ext).first.to_s
    res.write(File.read(path))
  end

  def match_static(path)
    return nil unless m = path.match(/\/public\/(?<file>[\w\.\/]+)/)
    file = m.names.zip(m.captures).to_h['file']
    "public/#{file}"
  end

end
