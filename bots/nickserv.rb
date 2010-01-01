module BitServ
  class NickServ < ServicesBot
    
    command ['id', 'identify'], 'Identifies to services for a nickname.', 'password' do |origin, params|
      if LDAP.user_bind origin, params.shift
        #sock.puts ":OperServ ! #services :SOPER: #{origin} as #{origin}"
        $sock.puts ":NickServ B #{origin} :You are now identified for \002#{origin}\002."
        #sock.puts ":NickServ B danopia :2 failed logins since last login."
        #sock.puts ":NickServ B danopia :Last failed attempt from: danopia!danopia@danopia-F985FA2D on Jan 01 00:25:26 2010."
        $sock.puts ":NickServ SVS2MODE #{origin} +rd #{Time.now.to_i}"
      else
        $sock.puts ":NickServ B #{origin} :Invalid password for \002#{origin}\002."
      end
    end
    
    command 'register', 'Registers a nickname.', 'password', 'email' do |origin, params|
      dn = $config['ldap']['auth_pattern'].gsub('{username}', origin) + ",#{$config['ldap']['base']}"
      attrs = {
        :cn => origin,
        :userPassword => params.shift,
        :mail => params.shift,
        :objectclass => ['x-bit-ircUser', 'top'],
        :uid => origin
      }
      
      LDAP.master_bind
      LDAP.ldap.add :dn => dn, :attributes => attrs
      if LDAP.ldap.get_operation_result.code == 0
        $sock.puts ":OperServ ! #{$config['services-channel']} :REGISTER: \002#{origin}\002 to \002#{attrs[:mail]}\002"
        $sock.puts ":NickServ SVS2MODE #{origin} +rd #{Time.now.to_i}"
        $sock.puts ":NickServ B #{origin} :\002#{origin}\002 is not registered to \002#{attrs[:mail]}\002, with the password \002#{attrs[:userPassword]}\002."
      else
        $sock.puts ":NickServ B #{origin} :An error occured while creating your account."
        puts "Result: #{LDAP.ldap.get_operation_result.code}"
        puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end
    
    command 'drop', 'Drops an account registration.', 'nickname', 'password' do |origin, params|
      if !LDAP.user_bind params[0], params[1]
        $sock.puts ":NickServ B #{origin} :Invalid password for \002#{params[0]}\002."
        next
      end
      
      dn = $config['ldap']['auth_pattern'].gsub('{username}', origin) + ",#{$config['ldap']['base']}"
      LDAP.ldap.delete :dn => dn
      
      if LDAP.ldap.get_operation_result.code == 0
        $sock.puts ":OperServ ! #{$config['services-channel']} :DROP: \002#{params[0]}\002 by \002#{origin}\002"
        $sock.puts ":NickServ SVS2MODE #{origin} -r+d 0"
        $sock.puts ":NickServ B #{origin} :\002#{params[0]}\002 has been dropped."
      else
        $sock.puts ":NickServ B #{origin} :An error occured while dropping your account."
        puts "Result: #{LDAP.ldap.get_operation_result.code}"
        puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end

  end
end
