module RComet
  VERSION         = '0.0.1'
  
  class Channel
    HANDSHAKE     = '/meta/handshake'
    CONNECT       = '/meta/connect'
    SUBSCRIBE     = '/meta/subscribe'
    UNSUBSCRIBE   = '/meta/unsubscribe'
    DISCONNECT    = '/meta/disconnect'
  end
  
  BAYEUX_VERSION  = '1.0'
end
