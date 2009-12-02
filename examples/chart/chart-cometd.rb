$:.unshift( "../../lib" )
require 'rcomet'

server = RComet::Server.new( :server => 'localhost', :port => 8990 )
graph_channel = server.add_channel( '/graph', [1,1,2,2,3,3,4,4] )
graph_channel.callback do |message|
  puts "someone send "
  p message
  puts 'on channel /graph'
  graph_channel.data = message['data']
end
server.start

while true
  graph_channel.data = [rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10)]
  sleep(5)
end
