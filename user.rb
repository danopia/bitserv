module BitServ
  class User
    attr_accessor :nick, :numeric, :timestamp, :ident, :ip, :server, :hops, :modes, :cloak, :base64, :realname, :account
    
    def initialize(nick)
      @name = nick
    end
    
  end
end
