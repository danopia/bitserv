module BitServ
  class NickServ < ServicesBot
    
    command ['identify', 'id'], 'Identifies to services for a nickname.', 'password' do |origin, params|
      if LDAP.user_bind origin.nick, params.shift
        #sock.puts ":OperServ ! #services :SOPER: #{origin} as #{origin}"
        notice origin, "You are now identified for ^B#{origin.nick}^B."
        #sock.puts ":NickServ B danopia :2 failed logins since last login."
        #sock.puts ":NickServ B danopia :Last failed attempt from: danopia!danopia@danopia-F985FA2D on Jan 01 00:25:26 2010."
        $sock.puts ":NickServ SVS2MODE #{origin.nick} +rd #{Time.now.to_i}"
      else
        notice origin, "Invalid password for ^B#{origin.nick}^B."
      end
    end
    
    command 'register', 'Registers a nickname.', 'password', 'email' do |origin, params|
      dn = $config['ldap']['auth_pattern'].gsub('{username}', origin.nick) + ",#{$config['ldap']['base']}"
      password = params.shift
      attrs = {
        :cn => origin.nick,
        :userPassword => `slappasswd -s #{password}`.chomp,
        :mail => params.shift,
        :objectclass => ['x-bit-ircUser', 'top'],
        :uid => origin.nick
      }
      
      LDAP.master_bind
      LDAP.ldap.add :dn => dn, :attributes => attrs
      if LDAP.success?
        $sock.puts ":OperServ ! #{$config['services-channel']} :REGISTER: \002#{origin.nick}\002 to \002#{attrs[:mail]}\002"
        $sock.puts ":NickServ SVS2MODE #{origin.nick} +rd #{Time.now.to_i}"
        notice origin, "^B#{origin.nick}^B is now registered to ^B#{attrs[:mail]}^B, with the password ^B#{password}^B."
      else
        notice origin, "An error occurred while creating your account."
        puts "Result: #{LDAP.ldap.get_operation_result.code}"
        puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end
    
    command 'drop', 'Drops an account registration.', 'nickname', 'password' do |origin, params|
      if !LDAP.user_bind params[0], params[1]
        notice origin, "Invalid password for ^B#{params[0]}^B."
        next
      end
      
      dn = $config['ldap']['auth_pattern'].gsub('{username}', origin.nick) + ",#{$config['ldap']['base']}"
      LDAP.ldap.delete :dn => dn
      
      if LDAP.success?
        $sock.puts ":OperServ ! #{$config['services-channel']} :DROP: \002#{params[0]}\002 by \002#{origin}\002"
        $sock.puts ":NickServ SVS2MODE #{origin.nick} -r+d 0"
        notice origin, "^B#{params[0]}^B has been dropped."
      else
        notice origin, "An error occurred while dropping your account."
        puts "Result: #{LDAP.ldap.get_operation_result.code}"
        puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end

  end
end
