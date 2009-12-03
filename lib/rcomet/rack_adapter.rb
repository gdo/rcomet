# The Rack::Adapter class allow you to use RComet as a Rack middleware
#
# Example :
#
#   map '/comet' do
#     run RComet::RackAdapter :port => 8282, :host => "localhost" do
#       # Server implementation...
#     end
#   end
#
require 'rubygems'
require 'rack'

module RComet
  class RackAdapter    
    def initialize(app = nil, options = nil)
      @app      = app if app.respond_to?(:call)
      @options  = [app, options].grep(Hash).first || {}
      
      if block_given?
        Thread.new do
          
        end
      end
    end
    
    def call(env)
      request = Rack::Request.new(env)
      
      case request.path_info
      when @endpoint
      else
        raise "Hum... something was wrong !"
      
      response = Rack::Response.new
      response.write "Il est #{Time::now}"
      response.finish
    end
  end
end