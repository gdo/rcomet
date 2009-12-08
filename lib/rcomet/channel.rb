module RComet
  class ChannelSet #:nodoc:
    def initialize
      @channels = Hash.new
    end
    
    def [](channel_or_path)
      channel = nil
      if( channel_or_path.class == RComet::Channel )
        return @channels[channel_or_path.path] if @channels.has_key?(channel_or_path.path)
        channel = channel_or_path
      else
        return @channels[channel_or_path] if @channels.has_key?(channel_or_path)
        channel = RComet::Channel.new( channel_or_path )
      end
      
      @channels[channel.path] = channel
      return channel
    end
    
    def []=(channel_or_path, data)
      channel = self[channel_or_path]
      channel.data( data )
      return channel
    end
  end
  
  class Channel
    HANDSHAKE     = '/meta/handshake'
    CONNECT       = '/meta/connect'
    SUBSCRIBE     = '/meta/subscribe'
    UNSUBSCRIBE   = '/meta/unsubscribe'
    DISCONNECT    = '/meta/disconnect'
    
    attr_reader :path, :handler
    
    # Create a new channel
    def initialize( path, data = nil )
      @path = path
      @users = Hash.new
      @data = data
      @handler = nil
    end
    
    # Send data to the channel or, if no parameter is given, get available data for the channel
    def data( data = nil, &block )
      unless data or block_given?
        return @data
      end
      
      if block_given?
        @data = yield( data )
      else
        @data = data
      end

      @users.each do |id, user|
        message = {
          'channel' => @path,
          'data' => @data,
          'clientId' => id
        }
        user.send( message )
      end
    end
    
    # Define the channel publishion callback
    def callback( &block )
      @handler = block
    end
    
    def add_user( user ) #:nodoc:
      @users[user.id] = user
    end
  end
end