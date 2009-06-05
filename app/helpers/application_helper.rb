# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def dump_request
    lines = [ ]
    request.env.keys.sort.each do |key|
      if key =~ /^rack\.|[A-Z_]+$/
        lines << "#{key}: #{request.env[key]}<br />"
      end
    end
    lines.join("")
  end
end
