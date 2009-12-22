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
      render :erb => :login
    end
  end
  
  class Chat < Route '/chat'
    def post
      @username = params["username"]
      @ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last }
      render :erb => :chat
    end
    
    def get
      redirect Index
    end
  end
end

Capcode.run( )
