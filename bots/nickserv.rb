module BitServ
  class NickServ < ServicesBot
    
    command ['identify', 'id'], 'Identifies to services for a nickname.', 'password'
    command 'register', 'Registers a nickname.', 'password', 'email'
    command 'drop', 'Drops an account registration.', 'nickname', 'password'
    
    def cmd_identify origin, password
      if LDAP.user_bind origin.nick, password
        #sock.puts ":OperServ ! #services :SOPER: #{origin} as #{origin}"
        notice origin, "You are now identified for ^B#{origin.nick}^B."
        #sock.puts ":NickServ B danopia :2 failed logins since last login."
        #sock.puts ":NickServ B danopia :Last failed attempt from: danopia!danopia@danopia-F985FA2D on Jan 01 00:25:26 2010."
        @link.send_from self.nick, 'SVS2MODE', origin, '+rd', Time.now.to_i # TODO: Use link abstraction!
      else
        notice origin, "Invalid password for ^B#{origin.nick}^B."
      end
    end
    
    def cmd_register origin, password, email
      dn = $config['ldap']['auth_pattern'].gsub('{username}', origin.nick) + ",#{$config['ldap']['base']}"
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
        @link.send_from self.nick, 'SVS2MODE', origin, '+rd', Time.now.to_i # TODO: Use link abstraction!
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
      
      dn = $config['ldap']['auth_pattern'].gsub('{username}', nickname) + ",#{$config['ldap']['base']}"
      LDAP.ldap.delete :dn => dn
      
      if LDAP.success?
        log 'drop', "^B#{nickname}^B by ^B#{origin}^B"
        @link.send_from self.nick, 'SVS2MODE', nickname, '-r+d', 0 # TODO: Use link abstraction!
        notice origin, "^B#{nickname}^B has been dropped."
      else
        notice origin, "An error occurred while dropping your account."
        puts "Result: #{LDAP.ldap.get_operation_result.code}"
        puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end

  end
end
