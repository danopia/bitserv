module BitServ
  class User
    attr_accessor :nick, :numeric, :timestamp, :ident, :ip, :server, :hops, :modes, :cloak, :base64, :realname, :account, :entry, :uid, :hostname
    
    def initialize(nick)
      puts "Remote client connected: #{nick}"
      @nick = nick
    end
    
    def nick=(newnick)
      puts "#{@nick} has changed nicks to #{newnick}"
      @nick = newnick
    end
    
    def quit message
      puts "#{@nick} quit: #{message}"
    end
    
    def dn
      LDAP.user_dn @nick
    end
    
    def to_s
      @nick
    end
    
    def inspect
      "#{@nick}!#{@ident}@#{@cloak}"
    end
  end
end
