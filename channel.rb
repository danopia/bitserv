module BitServ
  class Channel
    attr_reader :name, :users
    attr_accessor :topic, :timestamp, :modes
    
    def initialize(name)
      @name = name
      @users = {}
    end
    
  end
end
