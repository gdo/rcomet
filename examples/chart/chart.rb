require 'rubygems'
require 'capcode'
require 'capcode/render/static'
# $:.unshift( "../../lib" )
# require 'rcomet'
# 
# @comet_thread = Thread.new do
#   server = RComet::Server.new( :server => 'localhost', :port => 8990 )
#   graph_channel = server.add_channel( '/graph', [1,1,2,2,3,3,4,4] )
#   server.start
#   
#   while true
#     graph_channel.data = [rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10)]
#     sleep(5)
#   end
# end

module Capcode
  set :static, "/static"
  set :verbose, true 
  
  class Index < Route '/'
    def get
      redirect '/static/chart.html'
    end
  end
end

Capcode.run( )
