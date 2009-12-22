$:.unshift( "../../lib" )
require 'rcomet'

server = RComet::Server.new( :host => '0.0.0.0', :port => 8990, :server => :mongrel, :mount => '/' ) {
  channel['/graph'] = [1,1,2,2,3,3,4,4]
  channel['/graph'].callback do |message|
    puts "someone send "
    p message['data']
    puts 'on channel /graph'
    channel['/graph'].data( message['data'] )
  end
}
server.start

while true
  server.channel['/graph'].data( [rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10),rand(10)] )
  sleep(5)
end
