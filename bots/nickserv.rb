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
      LDAP.bot_bind self
      if client.entry = LDAP.select(client.dn, :attributes => ['*', 'memberof'])
        notice client, "This nickname is registered. Please choose a different nickname, or identify via ^B/msg #{@nick} identify <password>^B."
      end
    end
    
    def create_cloak account
      account.memberof.last =~ /^ou=([^,]+),ou=([^,]+),/
      "#{account.uid}/#{$2}/#{$1}"
    end
    
    command ['identify', 'id'], 'Identifies to services for a nickname.', 'password'
    command 'register', 'Registers a nickname.', 'password', 'email'
    command 'drop', 'Drops an account registration.', 'nickname', 'password'
    command 'info', 'Displays information on registrations.', 0, 'account'
    
    def cmd_identify origin, password
      LDAP.user_bind origin.nick, password
      origin.entry = LDAP.select origin.dn, :attributes => ['*', 'memberof']
      
      if origin.entry # LDAP.success?
        #sock.puts ":OperServ ! #services :SOPER: #{origin} as #{origin}"
        notice origin, "You are now identified for ^B#{origin.nick}^B."
        #sock.puts ":NickServ B danopia :2 failed logins since last login."
        #sock.puts ":NickServ B danopia :Last failed attempt from: danopia!danopia@danopia-F985FA2D on Jan 01 00:25:26 2010."
        #@link.send_from self, 'SVS2MODE', origin, '+rd', Time.now.to_i # TODO: Use link abstraction!
        
        origin.cloak = create_cloak origin.entry
        @services.uplink.set_cloak self, origin if origin.cloak
      else
        notice origin, "Invalid password for ^B#{origin.nick}^B."
        # hopefully it returns nil on error
      end
    end
    
    def cmd_info origin, account=nil
      account ||= origin.nick
      entry = LDAP.select LDAP.user_dn(account), :attributes => ['*', 'memberof']
      
      if entry
        notice origin, "Information on ^B#{entry.uid}^B (account #{account}):"
        notice origin, "Cloak      : #{create_cloak entry}"
        notice origin, "Name       : #{entry.cn}"
        notice origin, "Email      : #{entry.mail}"
        notice origin, "URL        : #{entry[:"x-bit-url"]}"
        
        first = "Groups"
        entry.memberof.each do |group|
          next unless group.count(',') > 4
          group =~ /^ou=([^,]+),ou=([^,]+),/
          notice origin, "#{first}     : #{$2} (#{$1})"
          first = "      "
        end
        
        notice origin, "*** ^BEnd of Info^B ***"
      else
        notice origin, "^B#{account}^B is not registered."
      end
    end
    
    def cmd_register origin, password, email
      attrs = {
        :cn => origin.nick,
        :userPassword => `slappasswd -s #{password}`.chomp,
        :mail => email,
        :objectclass => ['x-bit-ircUser', 'top'],
        :uid => origin.nick
      }
      
      LDAP.bot_bind self
      p LDAP.create(origin.dn, attrs) # Does this return the entry?
      if LDAP.success?
        log 'register', "^B#{origin.nick}^B to ^B#{attrs[:mail]}^B"
        #@link.send_from self.nick, 'SVS2MODE', origin, '+rd', Time.now.to_i # TODO: Use link abstraction!
        
        #origin.cloak = "#{origin.nick}::EighthBit::User"
        #@services.uplink.set_cloak self, origin
        
        notice origin, "^B#{origin.nick}^B is now registered to ^B#{email}^B, with the password ^B#{password}^B."
      else
        notice origin, "An error occurred while creating your account."
        puts "Result: #{LDAP.ldap.get_operation_result.code}"
        puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end
    
    def cmd_drop origin, nickname, password
      LDAP.user_bind nickname, password
      LDAP.delete LDAP.user_dn(nickname)
      
      if LDAP.success?
        log 'drop', "^B#{nickname}^B by ^B#{origin}^B"
        #@services.uplink.send_from self.nick, 'SVS2MODE', nickname, '-r+d', 0 # TODO: Use link abstraction!
        notice origin, "^B#{nickname}^B has been dropped."
      else
        notice origin, "Invalid password for ^B#{nickname}^B. #{LDAP.ldap.get_operation_result.code} #{LDAP.ldap.get_operation_result.message}"
        #notice origin, "An error occurred while dropping your account."
        #puts "Result: #{LDAP.ldap.get_operation_result.code}"
        #puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end

  end
end
