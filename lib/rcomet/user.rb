module RComet
  class User
    attr_reader :id
    attr_accessor :connected
    
    # Create a new Comet user
    def initialize
      @connected = false
      @id = ''
      16.times do |i|
        @id << ?A+rand(50)
      end
      
      @channels = Hash.new
      @event_mutex = Mutex.new
      @messages = []
    end
    
    def wait( messages ) #:nodoc:
      @continue = true
      @messages << messages
      while @continue; end
      
      messages = @messages.clone
      @messages = []
      return messages
    end
    
    def send( message ) #:nodoc:
      if @connected == false
        puts "Des données sont prêtes mais pas le user ##{@id}"
        ## ADD TIMEOUT !
      end
      
      @messages << message
      @continue = false
    end
    
    # Subscribe to a given channel
    def subscribe( channel )
      channel.add_user( self )
      @channels[channel.path] = channel
    end
    
    # Unsubscribe to a given channel
    def unsubscribe( channel )
      c = @channels.delete(channel)
      c.delete_user(self) if c
    end
    
    def has_channel? #:nodoc:
      return( not @channels.empty? )
    end
  end
end