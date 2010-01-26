require 'ldap'

module BitServ
  class NickServ < ServicesBot
  
    def on_new_client client
      check_nick_reg client
    end
    
    def on_nick_change old_nick, client
      check_nick_reg client
    end
    
    def check_nick_reg client
      client.dn = LDAP.user_dn client.nick
      
      client.entry = LDAP.ldap.search :base => client.dn
      if client.entry
        client.entry = client.entry.first
        notice client, "This nickname is registered. Please choose a different nickname, or identify via ^B/msg #{@nick} identify <password>^B."
      end
    end
    
    def create_cloak account
      entries = LDAP.ldap.search :base => account[:dn].first, :filter => Net::LDAP::Filter.eq('objectclass', 'x-bit-ircGroupRole')
      return nil if entries.nil? || entries.empty?
      entry = entries.first
      "#{account[:uid].first}/#{entry[:ou].first}/#{entry[:cn].first}"
    end
    
    command ['identify', 'id'], 'Identifies to services for a nickname.', 'password'
    command 'register', 'Registers a nickname.', 'password', 'email'
    command 'drop', 'Drops an account registration.', 'nickname', 'password'
    command 'info', 'Displays information on registrations.', 0, 'account'
    
    def cmd_identify origin, password
      if LDAP.user_bind origin.nick, password
        origin.dn = LDAP.user_dn origin.nick
        origin.entry = LDAP.ldap.search(:base => origin.dn, :filter => Net::LDAP::Filter.eq('objectclass', 'x-bit-ircUser')).first
        
        #sock.puts ":OperServ ! #services :SOPER: #{origin} as #{origin}"
        notice origin, "You are now identified for ^B#{origin.nick}^B."
        #sock.puts ":NickServ B danopia :2 failed logins since last login."
        #sock.puts ":NickServ B danopia :Last failed attempt from: danopia!danopia@danopia-F985FA2D on Jan 01 00:25:26 2010."
        #@link.send_from self, 'SVS2MODE', origin, '+rd', Time.now.to_i # TODO: Use link abstraction!
        
        origin.cloak = create_cloak origin.entry
        @services.uplink.set_cloak self, origin if origin.cloak
      else
        notice origin, "Invalid password for ^B#{origin.nick}^B."
      end
    end
    
    def cmd_info origin, account=nil
      account ||= origin.nick
      
      dn = LDAP.user_dn account
      entries = LDAP.ldap.search :base => dn, :filter => Net::LDAP::Filter.eq('objectclass', 'x-bit-ircUser')
      
      if entries
        entry = entries.shift
        notice origin, "Information on ^B#{entry[:uid].first}^B (account #{account}):"
        notice origin, "Cloak      : #{create_cloak entry}"
        notice origin, "Name       : #{entry[:cn].first}"
        notice origin, "Email      : #{entry[:mail].first}"
        notice origin, "URL        : #{entry[:"x-bit-url"].first}"
        
        first = "Groups"
        LDAP.ldap.search(:base => entry[:dn].first, :filter => Net::LDAP::Filter.eq('objectclass', 'x-bit-ircGroupRole')).each do |group|
          notice origin, "#{first}     : #{group[:ou].first} (#{group[:cn].first})"
          first = "      "
        end
        
        notice origin, "*** ^BEnd of Info^B ***"
      else
        notice origin, "^B#{account}^B is not registered."
      end
    end
    
    def cmd_register origin, password, email
      dn = LDAP.user_dn origin.nick
      attrs = {
        :cn => origin.nick,
        :userPassword => `slappasswd -s #{password}`.chomp,
        :mail => email,
        :objectclass => ['x-bit-ircUser', 'top'],
        :uid => origin.nick
      }
      
      LDAP.bot_bind self
      LDAP.ldap.add :dn => dn, :attributes => attrs
      if LDAP.success?
        log 'register', "^B#{origin.nick}^B to ^B#{attrs[:mail]}^B"
        #@link.send_from self.nick, 'SVS2MODE', origin, '+rd', Time.now.to_i # TODO: Use link abstraction!
        
        origin.cloak = "#{origin.nick}::EighthBit::User"
        @services.uplink.set_cloak self, origin
        
        notice origin, "^B#{origin.nick}^B is now registered to ^B#{email}^B, with the password ^B#{password}^B."
      else
        notice origin, "An error occurred while creating your account."
        puts "Result: #{LDAP.ldap.get_operation_result.code}"
        puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end
    
    def cmd_drop origin, nickname, password
      if !LDAP.user_bind nickname, password
        notice origin, "Invalid password for ^B#{nickname}^B."
        return
      end
      
      dn = LDAP.user_dn nickname
      LDAP.ldap.delete :dn => dn
      
      if LDAP.success?
        log 'drop', "^B#{nickname}^B by ^B#{origin}^B"
        @services.uplink.send_from self.nick, 'SVS2MODE', nickname, '-r+d', 0 # TODO: Use link abstraction!
        notice origin, "^B#{nickname}^B has been dropped."
      else
        notice origin, "An error occurred while dropping your account."
        puts "Result: #{LDAP.ldap.get_operation_result.code}"
        puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end

  end
end
