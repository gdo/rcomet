$:.unshift( "../../lib" )
require 'rcomet'

server = RComet::Server.new( :host => '0.0.0.0', :port => 8990, :server => :mongrel, :mount => '/' )
server.channel['/graph'] = [1,1,2,2,3,3,4,4]
server.channel['/graph'].callback do |data|
  puts "someone send "
  p data
  puts 'on channel /graph'
  server.channel['/graph'].data( data )
end
server.start

while true
  server.channel['/graph'].data( [rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10)] )
  sleep(5)
end
