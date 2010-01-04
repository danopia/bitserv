module BitServ
  class User
    attr_accessor :nick, :numeric, :timestamp, :ident, :ip, :server, :hops, :modes, :cloak, :base64, :realname, :account, :dn, :entry
    
    def initialize(nick)
      @nick = nick
      puts "Remote client connected: #{@nick}"
      
      check_nick_reg
    end
    
    def nick=(newnick)
      puts "#{@nick} has changed nicks to #{newnick}"
      @nick = newnick
      
      check_nick_reg
    end
    
    def quit message
      puts "#{@nick} quit: #{message}"
    end
    
    
    def check_nick_reg
      @dn = $config['ldap']['auth_pattern'].gsub('{username}', @nick) + ",#{$config['ldap']['base']}"
      
      # TODO: Goes in a NickServ hook! NOT HERE!
      @entry = LDAP.ldap.search :base => @dn
      if @entry
        @entry = @entry.first
        #$uplink.send ":NickServ", 'B', @nick, "This nickname is registered. Please choose a different nickname, or identify via \002/msg NickServ identify <password>\002."
      end
    end
  end
end
