require 'rubygems'
require 'capcode'
require 'capcode/render/static'
require 'capcode/render/json'
require '../../lib/rcomet'


@comet_thread=Thread.new do
  server=RComet::Server.new('localhost',8990)
  graph_channel=RComet::Channel.new('/graph',[1,1,2,2,3,3,4,4])
  server.add_channel(graph_channel)
  server.start
  
  while true
    graph_channel.update_data([rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10)])
    sleep(5)
  end
end

module Capcode
  
  set :static, "/static"
  set :verbose, true 
end

def notify_change
end

Capcode.run( )
