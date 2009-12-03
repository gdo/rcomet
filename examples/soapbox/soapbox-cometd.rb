$:.unshift( "../../lib" )
require 'rcomet'

server = RComet::Server.new( :server => '0.0.0.0', :port => 8990 )
login = server.add_channel( '/login' )
login.callback do |data|
  puts "someone send "
  p data
  puts 'on channel /login'
  server.add_channel( "/from/#{data}" )
end

server.start

while true
end
