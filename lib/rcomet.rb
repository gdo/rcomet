require 'rubygems'
require 'rcomet/server'

module RComet
  VERSION = '0.0.1'
  
  BAYEUX_VERSION   = '1.0'
  JSONP_CALLBACK   = 'jsonpcallback'
  CONNECTION_TYPES = %w[long-polling callback-polling]
end