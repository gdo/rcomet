require 'rubygems'
require 'capcode'
require 'capcode/render/static'

module Capcode
  set :static, "/static"
  set :verbose, true 
  
  class Index < Route '/'
    def get
      redirect '/static/soapbox.html'
    end
  end
end

Capcode.run( )
