module RComet
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
end