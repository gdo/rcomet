$:.unshift( "../../lib" )
require 'rcomet'

server = RComet::Server.new( :server => '0.0.0.0', :port => 8990 )
graph_channel = server.add_channel( '/graph', [1,1,2,2,3,3,4,4] )
graph_channel.callback do |data|
  puts "someone send "
  p data
  puts 'on channel /graph'
  graph_channel.data = data
end
server.start

while true
  graph_channel.data = [rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10)]
  sleep(5)
end
