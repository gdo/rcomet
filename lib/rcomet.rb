##Comet server with bayeux protocol for Manag

##TODO Restreindre certain canaux à des utilisateurs authentifiés
##TODO Faire les Spec

require 'rubygems'
require 'json'
require 'webrick/httprequest'
require 'webrick/httpresponse'

require 'rcomet/constants'
require 'rcomet/error'
require 'rcomet/channel'
require 'rcomet/user'
require 'rcomet/server'
