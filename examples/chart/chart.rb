require 'rubygems'
require 'capcode'
require 'capcode/render/static'
require 'capcode/render/erb'

module Capcode
  set :static, "static"
  set :erb, "static"
  set :verbose, true 
  
  class Index < Route '/'
    def get
      @ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last }
      render :erb => :chart
    end
  end
end

Capcode.run( )
