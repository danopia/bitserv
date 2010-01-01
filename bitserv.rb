require 'yaml'
require 'socket'

require 'rubygems'
require 'net/ldap'

config = YAML.load open('bitserv.yaml')
$config = config
me = config['hostname']


module LDAP
  Config = $config['ldap']
  
  def self.base
    Config['base']
  end

  def self.ldap
    @ldap ||= create_ldap
  end
  
  def self.create_ldap
    ldap = Net::LDAP.new
    ldap.host = Config['hostname'] || 'localhost'
    ldap.port = (Config['port'] || 389).to_i
    ldap
  end
  
  def self.bind node=nil, pass=nil
    ldap.auth "#{node},#{base}", pass
    ldap.bind
  end
  
  def self.user_bind username, password
    bind Config['auth_pattern'].gsub('{username}', username), password
  end
  
  def self.master_bind
    bind Config['master_bind']['node'], Config['master_bind']['password']
  end
end


sock = TCPSocket.new(config['uplink']['hostname'], config['uplink']['port'].to_i)

bots = %w{NickServ ChanServ MemoServ OperServ Global}

sock.puts "PASS #{config['uplink']['password']}"
sock.puts "PROTOCTL TOKEN NICKv2 VHP NICKIP UMODE2 SJOIN SJOIN2 SJ3 NOQUIT TKLEXT"
sock.puts "SERVER #{me} 1 :#{config['description']}"

bots.each do |bot|
  sock.puts ":#{me} KILL #{bot} :#{me} (Attempt to use service nick)"
  sock.puts "NICK #{bot} 1 #{Time.now.to_i} #{bot} #{me} #{me} 0 +ioS * :Your standard #{bot}, minus any features"
end

stamps = {}

sock.puts "PING :#{me}"

joined_chan = false

while data = sock.gets
  puts data
  
  parts = data.chomp.split ' :', 2
  args = parts.shift.split ' '
  args << parts.shift if parts.any?
  
  origin = nil
  origin = args.shift[1..-1] if args.first[0,1] == ':'
  
  command = args.shift
  case command
  
    when 'NOTICE'
      puts args.last
      
    when 'PROTOCTL'
      puts "Procotol options: #{args.join(', ').downcase}"
    
    when 'PASS'
      puts "Received a link password"
    
    when 'SERVER' # server, numeric, description
      puts "Uplink server is #{args[0]}, numeric #{args[1]}: #{args[2]}"
    
    when 'SMO'
      puts "Server message to #{args[0]}: #{args[1]}"
    
    when '&' # nick, server numerc?, timestamp, ident, ip, server, servhops?, umode, cloak, base64, realname
      puts "Remote client connected: #{args[0]}"
      #sock.puts ":NickServ NOTICE #{args[0]} :Hey there."
    
    when '~' # timestamp, channel, list
      puts "Got user list for #{args[1]}: #{args[2]}"
      sock.puts ":#{me} SJOIN #{args[0]} #{args[1]} + :@ChanServ" unless stamps[args[1]]
      stamps[args[1]] = args[0]
      if args[1] == config['services-channel']
        (bots - ['ChanServ']).each do |bot|
          sock.puts ":#{me} SJOIN #{args[0]} #{args[1]} + :@#{bot}"
        end
        joined_chan = true
      end
    
    when 'H' # kick; channel, kickee, message
      puts "#{origin} kicked #{args[1]} from #{args[0]} (#{args[2]})"
      if args[1] == 'ChanServ'
        sock.puts ":#{me} SJOIN #{stamps[args[0]]} #{args[0]} + :@ChanServ"
        sock.puts ":ChanServ H #{args[0]} #{origin} :REVENGEEEEE!"
      end
    
    when ')' # channel, setter, when, topic
      puts "Topic for #{args[0]}: #{args.last}"
    
    when '!' # channel, message
      puts "#{origin} said on #{args[0]}: #{args[1]}"
      if args[1] =~ /^\001ACTION kicks ChanServ/
        sock.puts ":ChanServ ! #{args[0]} :ow"
      end
      
      if args[0] == 'NickServ'
        params = args[1].split
        cmd = params.shift.downcase
        case cmd
          
          when 'id', 'identify'
            if LDAP.user_bind origin, params.shift
              #sock.puts ":OperServ PRIVMSG #services :SOPER: #{origin} as #{origin}"
              sock.puts ":NickServ NOTICE #{origin} :You are now identified for \002#{origin}\002."
              #sock.puts ":NickServ NOTICE danopia :2 failed logins since last login."
              #sock.puts ":NickServ NOTICE danopia :Last failed attempt from: danopia!danopia@danopia-F985FA2D on Jan 01 00:25:26 2010."
              sock.puts ":NickServ SVS2MODE #{origin} +rd #{Time.now.to_i}"
            else
              sock.puts ":NickServ NOTICE #{origin} :Invalid password for \002#{origin}\002."
            end
          
          when 'register'
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
              sock.puts ":OperServ ! #{config['services-channel']} :REGISTER: \002#{origin}\002 to \002#{attrs[:mail]}\002"
              sock.puts ":NickServ SVS2MODE #{origin} +rd #{Time.now.to_i}"
              sock.puts ":NickServ NOTICE #{origin} :\002#{origin}\002 is not registered to \002#{attrs[:mail]}\002, with the password \002#{attrs[:userPassword]}\002."
            else
              sock.puts ":NickServ NOTICE #{origin} :An error occured while creating your account."
              puts "Result: #{LDAP.ldap.get_operation_result.code}"
              puts "Message: #{LDAP.ldap.get_operation_result.message}"
            end
          
        end
      end
    
    when 'AO' # 10 1262304315 2309 MD5:1f93b28198e5c6a138cf22cf14883316 0 0 0 :Danopia
      
    
    when 'ES'
      unless joined_chan
        sock.puts ":#{me} ~ #{Time.now.to_i} #{config['services-channel']} :@#{bots.join ' @'}"
        joined_chan = true
      end
      
      sock.puts ":#{me} GLOBOPS :Finished synchronizing with network in -0.01 ms."
      puts "Done syncing."
    
    when '9'
      puts "Server ponged."
    
    when '8'
      puts "Server pinged."
      sock.puts ":#{me} 9 #{me} :#{args.last}"
    
    when 'GLOBOPS'
      puts "Global op message: #{args.last}"
    
    when 'ERROR'
      puts "ERROR! #{args.first}"
      exit
      
    else
      puts "Unknown packet: #{data}"
  end
end
