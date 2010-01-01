module BitServ
  class NickServ < ServicesBot
    
    command ['id', 'identify'], 'Identifies to services for a nickname.', 'password' do |origin, params|
      if LDAP.user_bind origin, params.shift
        #sock.puts ":OperServ PRIVMSG #services :SOPER: #{origin} as #{origin}"
        $sock.puts ":NickServ NOTICE #{origin} :You are now identified for \002#{origin}\002."
        #sock.puts ":NickServ NOTICE danopia :2 failed logins since last login."
        #sock.puts ":NickServ NOTICE danopia :Last failed attempt from: danopia!danopia@danopia-F985FA2D on Jan 01 00:25:26 2010."
        $sock.puts ":NickServ SVS2MODE #{origin} +rd #{Time.now.to_i}"
      else
        $sock.puts ":NickServ NOTICE #{origin} :Invalid password for \002#{origin}\002."
      end
    end
    
    command 'register', 'Registers a nickname.', 'password', 'email' do |origin, params|
      dn = config['ldap']['auth_pattern'].gsub('{username}', origin)
      dn += ",#{config['ldap']['base']}"
      puts dn
      attrs = {
        :cn => origin,
        :userPassword => args.shift,
        :mail => args.shift,
        :objectclass => ['x-bit-ircUser', 'top'],
        :uid => origin
      }
      
      p LDAP.master_bind
      if LDAP.ldap.add :dn => dn, :attributes => attrs
        $sock.puts ":OperServ ! #{config['services-channel']} :REGISTER: \002#{origin}\002 to \002#{attrs[:mail]}\002"
        $sock.puts ":NickServ SVS2MODE #{origin} +rd #{Time.now.to_i}"
        $sock.puts ":NickServ NOTICE #{origin} :\002#{origin}\002 is not registered to \002#{attrs[:mail]}\002, with the password \002#{attrs[:userPassword]}\002."
      else
        $sock.puts ":NickServ NOTICE #{origin} :An error occured while creating your account."
        puts "Result: #{LDAP.ldap.get_operation_result.code}"
        puts "Message: #{LDAP.ldap.get_operation_result.message}"
      end
    end

  end
end
