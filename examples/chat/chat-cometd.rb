$:.unshift("../../lib")
require 'rcomet'

users = {}

RComet::Server.new( :host => '0.0.0.0', :port => 8990, :mount => '/', :server => :mongrel ) {

  timeout do |user|
   puts "*** User ID:#{user.id} (aka #{users[user.id]}) is not ready !"
  end

	channel['/users']
	
	channel['/login'].callback do |message|
    puts "*** Login : #{message['data']}"
		users.merge!({ message['clientId'] => message['data'] })
		channel['/users'].data( users.values )
	end
	
	channel['/logout'].callback do |message|
	 users.delete(message['clientId'])
	 channel['/users'].data( users.values )
	end
	
	channel['/message'].callback do |message|
		channel['/message'].data( message['data'] )
	end
}.start

while true; end