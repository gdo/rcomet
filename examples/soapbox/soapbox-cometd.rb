$:.unshift( "../../lib" )
require 'rcomet'

RComet::Server.new( :host => '0.0.0.0', :port => 8990, :mount => '/', :server => :mongrel ) {
  channel['/login'].callback do |data|
    puts "someone send "
    p data
    puts 'on channel /login'
    channel["/from/#{data}"]
  end
}.start

while true
end
