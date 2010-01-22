module BitServ
  class Channel
    attr_reader :name
    attr_accessor :topic, :timestamp, :modes, :users
    
    def initialize(name)
      @name = name
      @users = {}
    end
    
    def include? user
      @users.has_key? user
    end
    
    def add_user user, modes=''
      @users[user] = modes
    end
    
    def user_modes user
      @users[user]
    end
    def set_user_modes user, modes
      @users[user] = modes
    end
    def user_has_mode? user, mode
      include?(user) && user_modes(user).include?(mode)
    end
    
    def op? user
      user_has_mode? user, 'o'
    end
  end
end
