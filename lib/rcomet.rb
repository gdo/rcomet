module RComet
  VERSION = '0.0.2'
  
  BAYEUX_VERSION   = '1.0'
  JSONP_CALLBACK   = 'jsonpcallback'
  CONNECTION_TYPES = %w[long-polling callback-polling]
  
  def self.random(size) #:nodoc:
    id = ''
    size.times do |i|
      id << ?A+rand(50).to_s
    end
    return id
  end
end
