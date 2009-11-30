module RComet
  class Channel
    attr_reader :path, :data
    attr_accessor :server
    def initialize(path,data=nil)
      @path = path
      @users = Hash.new
      @data = data
    end

    #It"s a deliver event messages
    def update_data(data)     
      @data=data

      @users.each do |id,user|
        response={
                    'channel' => @path,
                    'data' => @data,
                    'clientId' => id
                  }
        user.send_data(response)
      end
    end
    
    def add_user(user)
      @users[user.id]=user
    end

    def delete_user(user)
      @users.delete(user.id)
    end
  end
end