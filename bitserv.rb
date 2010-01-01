require 'yaml'
require 'socket'

config = YAML.load open('bitserv.yaml')
me = config['hostname']

sock = TCPSocket.new(config['uplink']['hostname'], config['uplink']['port'].to_i)

bots = %w{NickServ ChanServ MemoServ OperServ Global}

sock.puts "PASS #{config['uplink']['password']}"
sock.puts "PROTOCTL TOKEN NICKv2 VHP NICKIP UMODE2 SJOIN SJOIN2 SJ3 NOQUIT TKLEXT"
sock.puts "SERVER #{me} 1 :#{config['description']}"

bots.each do |bot|
  sock.puts ":#{me} KILL #{bot} :#{me} (Attempt to use service nick)"
  sock.puts "NICK #{bot} 1 #{Time.now.to_i} #{bot} #{me} #{me} 0 +ioS * :Your standard #{bot}, minus any features"
end

sock.puts "PING :#{me}"

joined_chan = false

while data = sock.gets
  parts = data.split ' :', 2
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
      sock.puts ":#{me} SJOIN #{args[0]} #{args[1]} + :@ChanServ"
      if args[1] == config['services-channel']
        (bots - ['ChanServ']).each do |bot|
          sock.puts ":#{me} SJOIN #{args[0]} #{args[1]} + :@#{bot}"
        end
        joined_chan = true
      end
    
    when ')' # channel, setter, when, topic
      puts "Topic for #{args[0]}: #{args.last}"
    
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
