$:.unshift( "../../lib" )
require 'rcomet/client'

x = RComet::Client.new( 'http://localhost:8990/' )

puts "-- handshake"
x.handshake

puts "-- login as `daemon'"
x.publish( '/login', "daemon" );

puts "-- subscriptions"
x.subscribe( "/from/greg" ) { |r|
  puts "#{r["username"]} : #{r["message"]}"
}
x.subscribe( "/from/daemon" ) { |r|
  puts "#{r["username"]} : #{r["message"]}"
}

puts "-- connect"
x.connect

msg = ""  
while msg != "quit"
  msg = $stdin.readline.chomp
  unless msg == "quit"
    channel = "/from/daemon"
    data = { "username" => "daemon", "message" => msg }
    r = x.publish( channel, data )
    unless r["successful"]
      puts "=> Message not send !"
    end
  end
end

x.disconnect
