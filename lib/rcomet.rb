##Comet server with bayeux protocol for Manag

##TODO Restreindre certain canaux à des utilisateurs authentifiés
##TODO Faire les Spec

require 'rubygems'
require 'json'
require 'webrick/httprequest'
require 'webrick/httpresponse'

module RComet

  VERSION='0.0.1'

  class RCometAddrInUse < Exception ; end

  class Channel
    attr_reader :path, :data
    attr_accessor :server
    def initialize(path,data=nil)
      @path=path
      @users=Hash.new
      @data=data
    end

    #It"s a deliver event messages
    def update_data(data)     
      @data=data

      @users.each do |id,user|
        response={
                    'channel' => @path,
                    'data' => @data,
                    'clientId' => id
                  }
        user.send_data(response)
      end
    end
    
    def add_user(user)
      @users[user.id]=user
    end

    def delete_user(user)
      @users.delete(user.id)
    end
  end

  class User
    attr_reader :id
    attr_accessor :status
    def initialize(server)
      @status=:unconnected
      str=''
      16.times do |i|
        str << ?A+rand(50)
      end
      @id=str

      @server=server
      @channels=Hash.new
      @mutex_network_info=Mutex.new
    end
    
    def set_network_info(response,http_request,socket)
      @mutex_network_info.synchronize do
        @response=response
        @http_request=http_request
        @socket=socket
      end
    end

    def send_data(message)
      @mutex_network_info.synchronize do
        if @response and @http_request and @socket
          @response << message
          @server.send_response(@response,@http_request,@socket)
          @response=@http_request=@socket=nil
        else
          puts "une donnée est prete mais pas le user"
        end
      end
    end

    def have_channel?
      return (not @channels.empty?)
    end

    def subscribe(channel)
      channel.add_user(self)
      @channels[channel.path]=channel
    end

    def unsubscribe(channel)
      c=@channels.delete(channel)
      c.delete_user(self) if c
    end
    
    def disconnect
      @channels.each do |path,channel|
        channel.delete_user(self)
      end
      @socket.close if @socket
      @status=:unconnected
    end
  end

  class Server
    def initialize(ip,port,logger=nil)
      @users=Hash.new
      @channels=Hash.new
      @logger=logger
      begin
        @tcp_server = TCPServer.new(ip,port)
      rescue Errno::EADDRINUSE
        raise RCometAddrInUse.new("Address already use #{ip}:#{port}")
      end
    end #end def initialize
    
    def add_channel(channel)
      channel.server=self
      @channels[channel.path]=channel
    end

    def get_channel(path)
      @channels[path]
    end

    def start
      @tcp_server_thread = Thread.new do
        while true
          http_request = WEBrick::HTTPRequest.new(:Logger=>@logger)
          socket = @tcp_server.accept
          http_request.parse(socket)
          
          if http_request.query['message']
            process(http_request,socket)
          else
            raise "Recu ce body #{http_request.body} il n'y a pas de message dedans"
          end          
        end
      end #end thread new
    end #end def start

    def process(http_request,socket)
      messages=JSON.parse(http_request.query['message'])
      
      if messages[0]['channel']=='/meta/handshake'
        process_handshake(messages,http_request,socket)
      elsif messages[0]['channel']=='/meta/connect'
        process_connect(messages,http_request,socket)
      elsif messages[0]['channel']=='/meta/disconnect'
        process_disconnect(messages,http_request,socket)
      elsif messages[0]['channel']=='/meta/subscribe'
        process_subscribe(messages,http_request,socket)
      else
        raise "autre channel #{messages[0]['channel']}"
      end
    rescue Object => e
      STDERR.puts e.message
      STDERR.puts e.backtrace.join("\n")
      exit(1)
    end #end def process


    def process_handshake(messages,http_request,socket)
      #Pour l'identification
      message=messages[0] #on doit ignorer les autres
      
      begin
        user=User.new(self)
      end while @users.has_key?(user.id)
      @users[user.id]=user

      response=[{
                  'channel'=> '/meta/handshake',
                  'id' => message['id'],
                  'version'=> '1.0',
                  'minimumVersion'=> '1.0',
                  'supportedConnectionTypes'=> ['long-polling','callback-polling'],
                  'clientId'=> user.id,
                  'successful'=> true
                }]

      send_response(response,http_request,socket)
    end

    def process_connect(messages,http_request,socket)
      message=messages[0] #on doit ignorer les autres
      time=Time.new
      
      ##Le connect sert lorsque il y a un login et un password pour ce connecter à un utilisateur en particulier

      user=@users[message['clientId']]
      if user
        user.status=:connected
        response=[{ 
                    'channel'=>'/meta/connect',
                    'id' => message['id'],
                    'clientId'=>message['clientId'],
                    'successful'=>true,
                    'timestamp'=>"#{time.hour}:#{time.min}:#{time.sec} #{time.year}"
                  }]
        if user.have_channel?
          #je passe dans le mode event des qu'il y a publication d'une donnée sur un des channels de l'utilisateur alors on repond
          ##TODO faire un timeout de 30s
          return user.set_network_info(response,http_request,socket)
        else
          return send_response(response,http_request,socket)
        end
      else
        response=[{ 
                    'channel'=>'/meta/connect',
                    'id' => message['id'],
                    'clientId'=>message['clientId'],
                    'successful'=>false,
                    'error'=> "402:#{message['clientId']}:Unknown Client ID"
                  }]
        return send_response(response,http_request,socket)
      end
      raise "Je ne dois jamais arriver là contrairement aux autres ordres"
    end

    def process_disconnect(messages,http_request,socket)
      message=messages[0] #on doit ignorer les autres
      time=Time.new

      user=@users[message['clientId']]
      if user
        response=[{ 
                    'channel'=>'/meta/disconnect',
                    'id' => message['id'],
                    'clientId'=>message['clientId'],
                    'successful'=>true
                  }]
        user.disconnect
        @users.delete(message['clientId'])
      else
        response=[{
                    'channel'=> '/meta/disconnect',
                    'id' => message['id'],
                    'clientId'=>message['clientId'],
                    'successful'=> false,
                    'error'=> "402:#{message['clientId']}:Unknown Client ID"
                  }]
      end
      send_response(response,http_request,socket)
    end

    def process_subscribe(messages,http_request,socket)
      message=messages[0] #on doit ignorer les autres
      time=Time.new

      user=@users[message['clientId']]
      if user
        channel=@channels[message['subscription']]
        if channel
          
          user.subscribe(channel)
          
          response=[{ 
                      'channel'=>'/meta/subscribe',
                      'id' => message['id'],
                      'clientId'=>message['clientId'],
                      'successful'=>true,
                      'subscription'=>message['subscription']
                    }]
          if channel.data
            response << { 
              'channel'=>message['subscription'],
              'id' => (message['id'].to_i+1).to_s,
              'data' => channel.data,
              'clientId'=>message['clientId'],
            }
          end
        else
          #Channel doesn't exist
          response=[{
                      'channel'=> '/meta/subscribe',
                      'id' => message['id'],
                      'clientId'=>message['clientId'],
                      'successful'=> false,
                      'subscription'=> message['subscription'],
                      'error'=> "404:#{message['subscription']}:Unknown Channel"
                    }]
        end
      else
        response=[{
                    'channel'=> '/meta/disconnect',
                    'id' => message['id'],
                    'clientId'=>message['clientId'],
                    'successful'=> false,
                    'error'=> "402:#{message['clientId']}:Unknown Client ID"
                  }]
      end
      send_response(response,http_request,socket)
    end

    def send_response(response,http_request,socket,close=true)
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

      puts "@@@ Send response #{http_response.body}"
      http_response['Size']=http_response.body.size
      http_response.send_response(socket)     
      socket.flush
      socket.close if close
    end

  end
end
