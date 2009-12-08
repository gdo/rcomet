$:.unshift( "../../lib" )
require 'rcomet'

server = RComet::Server.new( :host => '0.0.0.0', :port => 8990, :mount => '/' )
server.channel['/login'].callback do |data|
  puts "someone send "
  p data
  puts 'on channel /login'
  server.channel["/from/#{data}"]
end

server.start

while true
end
