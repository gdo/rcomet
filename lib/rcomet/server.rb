require 'webrick/httprequest'
require 'webrick/httpresponse'
require 'logger'

module RComet
  class Server
    # Create a news server
    #
    # Options :
    # * :server : server name or IP
    # * :port : server port
    # * :logger : logger
    def initialize( options = {} )
      opts = {
        :server => "0.0.0.0",
        :port => 8990,
        :logger => Logger.new(STDOUT)
      }.merge( options )
      
      @users    = Hash.new
      @channels = Hash.new
      @logger   = opts[:logger]
      
      begin
        @tcp_server = TCPServer.new( opts[:server], opts[:port] )
      rescue Errno::EADDRINUSE
        raise RCometAddrInUse, "Address #{opts[:server]}:#{opts[:port]} already use!"
      end
    end
    
    # Add a new channel
    #
    # Example :
    #
    #   server = RComet::Server.new( :server => 'localhost', :port => 8990 )
    #   graph_channel = RComet::Channel.new( '/graph', [1,1,2,2,3,3,4,4] )
    #   server.add_channel( graph_channel )
    #
    # Or
    #
    #   server = RComet::Server.new( :server => 'localhost', :port => 8990 )
    #   graph_channel = server.add_channel( '/graph', [1,1,2,2,3,3,4,4] )
    def add_channel( channel_or_path, data = nil )
      channel = nil
      if( channel_or_path.class == RComet::Channel )
        channel = channel_or_path
      else
        channel = RComet::Channel.new( channel_or_path, data )
      end
      
      # Set server for the channel
      channel.server = self
      # Set channel path
      @channels[channel.path] = channel
      
      return channel
    end
    
    # Return the channel for the given path
    def get_channel( channel_or_path )
      if( channel_or_path.class == RComet::Channel )
        return @channels[channel_or_path.path]
      else
        return @channels[channel_or_path]
      end
    end
    
    # Start the RComet server
    def start
      @tcp_server_thread = Thread.new do
        while true
          http_request = WEBrick::HTTPRequest.new( :Logger => @logger )
          socket = @tcp_server.accept
          http_request.parse(socket)
          
          if http_request.query['message']
            process( http_request, socket )
          else
            raise RCometInvalidRequest, "Request body `#{http_request.body}' invalide!"
          end          
        end
      end
    end
    
    def send_response( response, http_request, socket, close = true ) #:nodoc:
      http_response = WEBrick::HTTPResponse.new(:Logger=>@logger,:HTTPVersion=>'1.1')
      http_response.request_method = http_request.request_method
      http_response.request_uri = http_request.request_uri
      http_response.request_http_version = http_request.http_version
      http_response.keep_alive = http_request.keep_alive?
      
      http_response.status=200                       # Success    
      if http_request.request_method == "GET"
        jsonp=http_request.query['jsonp']
        http_response.body="#{jsonp}(#{JSON.generate(response)});"
        http_response['Content-Type'] = 'text/javascript'
      else
        raise "TODO"
      end

      # puts "@@@ Send response #{http_response.body}"
      http_response['Size']=http_response.body.size
      http_response.send_response(socket)     
      socket.flush
      socket.close if close
    end

    private
    
    # Request process dispatcher
    def process( http_request, socket ) #:nodoc:
      messages = JSON.parse( http_request.query['message'] )

      case messages[0]['channel'] 
        when RComet::Channel::HANDSHAKE
          process_handshake( messages, http_request, socket )
        when RComet::Channel::CONNECT
          process_connect( messages, http_request, socket )
        when RComet::Channel::DISCONNECT
          process_disconnect( messages, http_request, socket )
        when RComet::Channel::SUBSCRIBE
          process_subscribe( messages, http_request, socket )
        when RComet::Channel::UNSUBSCRIBE
          process_unsubscribe( messages, http_request, socket )
        else
          process_channel( messages, http_request, socket )
      end
    rescue Object => e
      STDERR.puts e.message
      STDERR.puts e.backtrace.join("\n")
      exit(1)
    end

    def process_handshake(messages,http_request,socket) #:nodoc:
      message = messages[0] #on doit ignorer les autres
      
      begin
        user = User.new( self )
      end while @users.has_key?(user.id)
      @users[user.id] = user

      response = {
        'channel'                   => RComet::Channel::HANDSHAKE,
        'id'                        => message['id'],
        'version'                   => '1.0',
        'minimumVersion'            => '1.0',
        'supportedConnectionTypes'  => ['long-polling','callback-polling'],
        'clientId'                  => user.id,
        'successful'                => true
      }

      send_response( [response], http_request, socket )
    end

    def process_connect(messages,http_request,socket) #:nodoc:
      message = messages[0] #on doit ignorer les autres
      
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
        user.status = :connected
        time = Time.new
        
        response << {
          'successful'  => true,
          'timestamp'   =>"#{time.hour}:#{time.min}:#{time.sec} #{time.year}"
        }
        
        if user.have_channel?
          #je passe dans le mode event des qu'il y a publication d'une donnée sur un des channels 
          # de l'utilisateur alors on repond
          ##TODO faire un timeout de 30s
          return user.set_network_info( [response], http_request, socket )
        else
          return send_response( [response], http_request, socket )
        end
      else
        # User does not exist!
        response << {
          'successful'  => false,
          'error'       => "402:#{message['clientId']}:Unknown Client ID"
        }
        
        return send_response( [response], http_request, socket )
      end
    end

    def process_disconnect(messages,http_request,socket) #:nodoc:
      message = messages[0] #on doit ignorer les autres

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
        user.disconnect
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
      send_response( [response], http_request, socket )
    end

    def process_subscribe(messages,http_request,socket) #:nodoc:
      message = messages[0] #on doit ignorer les autres

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
          
          if channel.data
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
      send_response( [response], http_request, socket )
    end
    
    def process_unsubscribe( messages, http_request, socket )
      message = messages[0] #on doit ignorer les autres

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
      send_response( [response], http_request, socket )
    end

    def process_channel( messages, http_request, socket )
      message = messages[0] #on doit ignorer les autres
      
      # Initialize response
      response = { 
        'channel' => message['channel']
      }
      response << { 'id' => message['id'] } if message.has_key?('id')

      channel = get_channel(message['channel'])      
      if channel.nil?
        response << {
          'successful'  => false,
          'error'       => "404:#{message['channel']}:Unknown Channel"
        }
      else
        response << {
          'successful'  => true
        }
      end
      send_response( [response], http_request, socket )
      
      unless channel.nil?
        if channel.handler.nil?
          channel.data = message['data']
        else
          channel.handler.call( message['data'] )
        end
      end
    end
  end
end