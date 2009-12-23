require 'rubygems'
require 'rcomet/rack_adapter'
require 'logger'

module RComet
  class Server
    # Create a new Comet server
    def initialize( options = {}, &block )
      @conf = {
        :host => "0.0.0.0",
        :port => 8990,
        :mount => "/comet",
        :log => $stdout,
        :server => :webrick
      }.merge( options )
      
      if block_given?
        @comet = RComet::RackAdapter.new( &block )
      else
        @comet = RComet::RackAdapter.new( )
      end
    end
    
    # Start the Comet server
    def start
      route = { @conf[:mount] => @comet }
      app = Rack::URLMap.new(route)
      app = Rack::ContentLength.new(app)
      app = Rack::CommonLogger.new(app, Logger.new(@conf[:log]))
      
      @main_loop = Thread.new do
        case @conf[:server].to_sym
        when :mongrel
          puts "** Starting Mongrel on #{@conf[:host]}:#{@conf[:port]}"
          @server = Rack::Handler::Mongrel.run( app, {:Port => @conf[:port], :Host => @conf[:host]} )
        when :webrick
          puts "** Starting WEBrick on #{@conf[:host]}:#{@conf[:port]}"
          @server = Rack::Handler::WEBrick.run( app, {:Port => @conf[:port], :BindAddress => @conf[:host]} )
        when :thin
          puts "** Starting Thin on #{@conf[:host]}:#{@conf[:port]}"
          @server = Rack::Handler::Thin.run( app, {:Port => @conf[:port], :Host => @conf[:host]} )
        end
        
        puts "Thread end !"
        exit
      end
      
      at_exit {
        puts "Quitting..."
      }
    end
    
    def method_missing(method_name, *args, &block) #:nodoc:
      @comet.send(method_name,*args, &block)
    end
  end
end