$:.unshift( "../../lib" )
require 'rcomet'

server = RComet::Server.new( :server => 'localhost', :port => 8990 )
login = server.add_channel( '/login' )
login.callback do |message|
  puts "someone send "
  p message
  puts 'on channel /login'
  server.add_channel( "/from/#{message}" )
end

server.start

while true
end
