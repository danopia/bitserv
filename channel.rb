module BitServ
  class Channel
    attr_reader :name
    attr_accessor :topic, :timestamp, :modes, :users
    
    def initialize(name)
      @name = name
      @users = []
    end
    
  end
end
