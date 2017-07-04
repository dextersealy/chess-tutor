require 'erb'
require 'byebug'

# This middleware traps exceptions and renders a stack trace

class ShowExceptions
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue => e
      ['500', {'Content-type' => 'text/html'}, [render_exception(e)]]
    end
  end

  private

  def render_exception(e)
    @exception = e

    # Get source file, line and code snippet
    file, @line = parse_backtrace(e.backtrace.first)
    @source = extract_snippet(file, @line) if file && @line

    template = File.read("lib/templates/rescue.html.erb")
    ERB.new(template).result(binding)
  end

  # Extract file name and line number from exception backtrace

  def parse_backtrace(backtrace)
    m = backtrace.match(/(?<file>[^:]+):(?<line>\d+)/)
    file, line = m.names.zip(m.captures).to_h.values_at("file", "line")
    [file, line.to_i]
  end

  # Retrieve N lines before and after the specified Location

  def extract_snippet(file, line, n_lines = 5)
    offset = [line - 1 - n_lines, 0].max
    lines = File.readlines(file)[offset...line + n_lines];
    lines.map.with_index do |line, idx|
      [offset + idx + 1, line]
    end
  end

end
