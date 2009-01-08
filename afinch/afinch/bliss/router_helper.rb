# A router helper. Makes this:
#   r.to(:controller => 'people') do |people|
#     people.match('/some_url').to(:action => 'some_url').name(:some_url)
#   end
# into this:
#   r.to(:controller => 'people') do |people|
#     people.simple_route(:some_url)
#   end
module Merb
  class Router
    class Behavior
      def simple_route(*names)
        if names.is_a?(Array) && names.length > 1
          names.each {|d| self.simple_route(d)}
        else
          u = names.to_a.first
          self.match("/#{u.to_s}").to(:action => u.to_s).name(u)
        end
      end
    end
  end
end
