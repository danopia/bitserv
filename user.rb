module BitServ
  class User
    attr_accessor :nick, :numeric, :timestamp, :ident, :ip, :server, :hops, :modes, :cloak, :base64, :realname, :account, :dn, :entry, :uid, :hostname
    
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
  end
end
