# The Rack::Adapter class allow you to use RComet as a Rack middleware
#
# Example :
#
#   use RComet::RackAdapter :port => 8282, :host => "localhost" do
#     # Server implementation...
#   end
#
require 'rubygems'
require 'rack'

module RComet
  class RackAdapter
    def initialize(app = nil, options = nil)
      @app      = app if app.respond_to?(:call)
      @options  = [app, options].grep(Hash).first || {}
    end
    
    def call(env)
    end
  end
end