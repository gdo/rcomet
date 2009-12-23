# The Rack::Adapter class allow you to use RComet as a Rack middleware
#
# Example :
#
#   map '/comet' do
#     run RComet::RackAdapter :mount => "/comet" do
#       # ...
#     end
#   end
#
require 'rack'
require 'json'

require 'rcomet'
require 'rcomet/core_ext'
require 'rcomet/server'
require 'rcomet/channel'
require 'rcomet/user'

module RComet
  class RackAdapter #:nodoc:
    def initialize(app = nil, options = nil, &block)
      @app      = app if app.respond_to?(:call)
      @options  = [app, options].grep(Hash).first
      @channels = RComet::ChannelSet.new
      @users    = Hash.new
      @timeout  = nil
      
      instance_eval(&block) if block
      return @app  
    end
    
    def call(env)
      request = Rack::Request.new(env)
      
      if request.params.empty?
        [404, {'Content-Type' => 'text/html'}, ""]
      else
        messages = JSON.parse(request.params['message'])
        jsonp    = request.params['jsonp'] || JSONP_CALLBACK
        get      = request.get?

        process( jsonp, messages, get )
      end
    end
    
    def channel
      @channels
    end
    
    def timeout( &block )
      @handler = block if block_given?
      @handler
    end
    
    def process( jsonp, messages, get )
      replies = []
      messages.each do |message|
        reply = nil
        case message['channel'] 
          when RComet::Channel::HANDSHAKE
            reply = handshake( message )
          when RComet::Channel::CONNECT
            reply = connect( message )
          when RComet::Channel::DISCONNECT
            reply = disconnect( message )
          when RComet::Channel::SUBSCRIBE
            reply = subscribe( message )
          when RComet::Channel::UNSUBSCRIBE
            reply = unsubscribe( message )
          else
            reply = handle( message )
        end
        if reply.class == Array
          replies.concat( reply )
        else
          replies << reply
        end
      end
      
      response = JSON.generate(replies)
      type = {'Content-Type' => 'text/json'}
      if get
        response = "#{jsonp}(#{response});"
        type = {'Content-Type' => 'text/javascript'}
      end
      
      [200, type, [response]]
    end
    
    def handshake( message )
      begin
        user = User.new(self)
      end while @users.has_key?(user.id)
      @users[user.id] = user
      
      response = {
        'channel'                   => RComet::Channel::HANDSHAKE,
        'version'                   => RComet::BAYEUX_VERSION,
        'minimumVersion'            => RComet::BAYEUX_VERSION,
        'supportedConnectionTypes'  => ['long-polling','callback-polling'],
        'clientId'                  => user.id,
        'successful'                => true
      }
      response << { 'id' => message['id'] } if message.has_key?('id')
      
      return response
    end
    
    def connect( message )
      # Initialize response
      response = { 
        'channel' => RComet::Channel::CONNECT,
        'clientId' => message['clientId']
      }
      response << { 'id' => message['id'] } if message.has_key?('id')

      # Get user for clientId
      user = @users[message['clientId']]
      if user
        # Ok, connect user
        user.connected = true
        time = Time.new
        response << {
          'successful'  => true,
          'timestamp'   =>"#{time.hour}:#{time.min}:#{time.sec} #{time.year}"
        }
        
        if user.has_channel?
          response = user.wait( response )
        end
        user.connected = false
      else
        # User does not exist!
        response << {
          'successful'  => false,
          'error'       => "402:#{message['clientId']}:Unknown Client ID"
        }
      end
      
      return response
    end
    
    def disconnect( message )
      # Initialize response message
      response = {
        'channel'     => RComet::Channel::DISCONNECT,
        'clientId'    => message['clientId']
      }
      response << { 'id' => message['id'] } if message.has_key?('id')
      
      # Get user for clientId
      user = @users[message['clientId']]
      if user
        # Ok, disconnect user
        user.connected = false
        @users.delete( message['clientId'] )
        
        # Complete reponse
        response << {
          'successful'  => true
        }
      else
        # User does nit exist!
        response << {
          'successful'  => false,
          'error'       => "402:#{message['clientId']}:Unknown Client ID"
        }
      end
      
      return response
    end
    
    def subscribe( message )
      response = {
        'channel'     => RComet::Channel::SUBSCRIBE,
        'clientId'    => message['clientId']
      }
      response << { 'id' => message['id'] } if message.has_key?('id')
      
      # Get user for clientId
      user = @users[message['clientId']]
      if user
        # Get channel
        channel = @channels[message['subscription']]
        if channel
          user.subscribe( channel )
          response << {
            'successful'    => true,
            'subscription'  => message['subscription']
          }
          
          unless channel.data.nil?
            response = [response]
            response << { 
              'channel'   => message['subscription'],
              'id'        => (message['id'].to_i+1).to_s,
              'data'      => channel.data
            }
          end
        else
          #Channel doesn't exist
          response << {
            'successful'    => false,
            'subscription'  => message['subscription'],
            'error'         => "404:#{message['subscription']}:Unknown Channel"
          }
        end
      else
        response << {
          'successful'  => false,
          'error'       => "402:#{message['clientId']}:Unknown Client ID"
        }
      end

      return response
    end
    
    def unsubscribe( message )
      # Initialize response
      response = {
        'channel'     => RComet::Channel::UNSUBSCRIBE,
        'clientId'    => message['clientId']
      }
      response << { 'id' => message['id'] } if message.has_key?('id')

      # Get user for clientId
      user = @users[message['clientId']]
      if user
        # Get channel
        channel = @channels[message['subscription']]
        if channel
          user.unsubscribe( channel )
          response << {
            'successful'    => true,
            'subscription'  => message['subscription']
          }
        else
          #Channel doesn't exist
          response << {
            'successful'    => false,
            'subscription'  => message['subscription'],
            'error'         => "404:#{message['subscription']}:Unknown Channel"
          }
        end
      else
        response << {
          'successful'  => false,
          'error'       => "402:#{message['clientId']}:Unknown Client ID"
        }
      end
      
      return response
    end
    
    def handle( message )
      # Initialize response
      response = { 
        'channel' => message['channel']
      }
      response << { 'id' => message['id'] } if message.has_key?('id')

      c = channel[message['channel']]
      if c.nil?
        response << {
          'successful'  => false,
          'error'       => "404:#{message['channel']}:Unknown Channel"
        }
      else
        response << {
          'successful'  => true
        }
      end
            
      Thread.new do
        unless c.nil?
          if c.handler.nil?
            c.data( message['data'] )
          else
            c.handler.call( message )
          end
        end
        return
      end
      
      return response      
    end    
  end
end