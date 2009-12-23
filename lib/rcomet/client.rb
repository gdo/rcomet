require 'net/http'
require 'uri'
require 'rubygems'
require 'json'
require 'rcomet'
require 'rcomet/channel'

module RComet
  class Client    
    def initialize( uri_or_string )
      @uri = uri_or_string
      @uri = URI.parse(@uri) if @uri.class == String
      @clientId = nil
      # @interval = nil
      @connection = nil
      @subscriptions = {}
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * clientId                           * successful
    #                * connectionType                     * clientId
    # MAY include:   * ext                 MAY include:   * error
    #                * id                                 * advice
    #                                                     * ext
    #                                                     * id
    #                                                     * timestamp
    def connect
      @connection.kill unless @connection.nil?
      @connection = Thread.new {
        faild = false
        while true
          id = RComet.random(32)
          message = {
            "channel" => RComet::Channel::CONNECT,
            "clientId" => @clientId,
            "connectionType" => "long-polling",
            "id" => id
          }
          r = send( message )
            
          if r[0]["id"] == id and r[0]["successful"] == true
            @subscriptions[r[1]["channel"]].call( r[1]["data"])
          elsif r[0]["successful"] == false
            faild = true
            break
          end
        end
        
        if faild
          handshake()
          connect()
        end
      }
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * clientId                           * successful
    # MAY include:   * ext                                * clientId
    #                * id                  MAY include:   * error
    #                                                     * ext
    #                                                     * id
    def disconnect
      unless @connection.nil?
        @connection.kill 
        message = {
          "channel" => RComet::Channel::DISCONNECT,
          "clientId" => @clientId,
          "id" => RComet.random(32)
        }
        r = send( message )
        ## TODO : Check response
      end
    end
    
    # Request
    # MUST include:  * channel
    #                * version
    #                * supportedConnectionTypes
    # MAY include:   * minimumVersion
    #                * ext
    #                * id
    # 
    # Success Response                             Failed Response
    # MUST include:  * channel                     MUST include:  * channel
    #                * version                                    * successful
    #                * supportedConnectionTypes                   * error
    #                * clientId                    MAY include:   * supportedConnectionTypes
    #                * successful                                 * advice
    # MAY include:   * minimumVersion                             * version
    #                * advice                                     * minimumVersion
    #                * ext                                        * ext
    #                * id                                         * id
    #                * authSuccessful
    def handshake
      id = RComet.random(32)
      message = {
        "channel" => RComet::Channel::HANDSHAKE,
        "version" => RComet::BAYEUX_VERSION,
        "supportedConnectionTypes" => [ "long-polling", "callback-polling" ],
        "id" => id
      }
      
      response = send( message )[0]
      if response["successful"] and response["id"] == id
        @clientId = response["clientId"]
        # @interval = response["advice"]["interval"]
      else
        raise
      end
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * data                               * successful
    # MAY include:   * clientId            MAY include:   * id
    #                * id                                 * error
    #                * ext                                * ext
    def publish( channel, data )
      message = {
        "channel" => channel,
        "data" => data, 
        "clientId" => @clientId,
        "id" => RComet.random(32)
      }
      r = send(message)[0]
      ## TODO : Check response
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * clientId                           * successful
    #                * subscription                       * clientId
    # MAY include:   * ext                                * subscription
    #                * id                  MAY include:   * error
    #                                                     * advice
    #                                                     * ext
    #                                                     * id
    #                                                     * timestamp
    def subscribe( channel, &block )
      @subscriptions[channel] = block if block_given?

      message = {
        "channel" => RComet::Channel::SUBSCRIBE,
        "clientId" => @clientId,
        "subscription" => channel,
        "id" => RComet.random(32)
      }
      
      r = send(message)
      ## TODO : Check response
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * clientId                           * successful
    #                * subscription                       * clientId
    # MAY include:   * ext                                * subscription
    #                * id                  MAY include:   * error
    #                                                     * advice
    #                                                     * ext
    #                                                     * id
    #                                                     * timestamp
    def unsubscribe( channels )
      channels = [channels] unless channels.class == Array
      channels.each do |c|
        @subscriptions.delete(c)
      end
      message = {
        "channel" => RComet::Channel::UNSUBSCRIBE,
        "clientId" => @clientId,
        "subscription" => channels,
        "id" => RComet.random(32)
      }
      
      r = send(message)
      ## TODO : Check response
    end
    
    private
    def send( message )
      res = Net::HTTP.post_form( @uri, { "message" => [message].to_json } )
      return JSON.parse( res.body )
    end
    
  end
end
