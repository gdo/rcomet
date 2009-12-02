module RComet
  class Channel
    attr_reader :path, :data, :handler
    attr_accessor :server
    
    # Create a new channel
    def initialize( path, data = nil )
      @path = path
      @users = Hash.new
      @data = data
      @handler = nil
    end

    # Update data
    #
    #   channel.update_data( [1,2,3,4] )
    #
    # or
    #
    #   channel.update_data( data = nil ) { |data| ... }
    #
    # or
    #
    #   channel.data = ... # YES, data not update_data !
    def update_data( data = nil, &block )
      if block_given?
        @data = yield( data )
      else
        @data = data
      end

      @users.each do |id, user|
        response = {
          'channel' => @path,
          'data' => @data,
          'clientId' => id
        }
        user.send_data( response )
      end
    end
    def data=( data ) #:nodoc:
      update_data( data )
    end
    
    def callback( &b )
      @handler = b
    end
    
    def add_user( user ) #:nodoc:
      @users[user.id] = user
    end

    def delete_user( user ) #:nodoc:
      @users.delete(user.id)
    end
  end
end