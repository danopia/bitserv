require 'yaml'
require 'socket'

config = YAML.load open('bitserv.yaml')

sock = TCPSocket.new(config['uplink-hostname'], config['uplink-port'].to_i)

sock.puts "PASS #{config['uplink-password']}"
sock.puts "PROTOCTL TOKEN NICKv2 VHP NICKIP UMODE2 SJOIN SJOIN2 SJ3 NOQUIT TKLEXT"
sock.puts "SERVER #{config['hostname']} 1 :#{config['description']}"
sock.puts ":#{config['hostname']} KILL NickServ :#{config['hostname']} (Attempt to use service nick)"
sock.puts "NICK NickServ 1 1262302719 NickServ #{config['hostname']} #{config['hostname']} 0 +ioS * :Nickname Services"
sock.puts ":#{config['hostname']} KILL BotServ :#{config['hostname']} (Attempt to use service nick)"
sock.puts "NICK BotServ 1 1262302719 BotServ #{config['hostname']} #{config['hostname']} 0 +ioS * :Bot Services"
sock.puts ":#{config['hostname']} KILL ChanServ :#{config['hostname']} (Attempt to use service nick)"
sock.puts "NICK ChanServ 1 1262302719 ChanServ #{config['hostname']} #{config['hostname']} 0 +ioS * :Channel Services"
sock.puts ":#{config['hostname']} KILL OperServ :#{config['hostname']} (Attempt to use service nick)"
sock.puts "NICK OperServ 1 1262302719 OperServ #{config['hostname']} #{config['hostname']} 0 +ioS * :Operator Services"
sock.puts ":#{config['hostname']} KILL Global :#{config['hostname']} (Attempt to use service nick)"
sock.puts "NICK Global 1 1262302719 Global #{config['hostname']} #{config['hostname']} 0 +ioS * :Network Announcements"
sock.puts ":#{config['hostname']} KILL MemoServ :#{config['hostname']} (Attempt to use service nick)"
sock.puts "NICK MemoServ 1 1262302719 MemoServ #{config['hostname']} #{config['hostname']} 0 +ioS * :Memo Services"
sock.puts "PING :#{config['hostname']}"

sleep 0.5
sock.puts ":#{config['hostname']} SJOIN 1261978832 #{config['services-channel']} + :@NickServ"
sock.puts ":#{config['hostname']} SJOIN 1261978832 #{config['services-channel']} + :@BotServ"
sock.puts ":#{config['hostname']} SJOIN 1261978832 #{config['services-channel']} + :@ChanServ"
sock.puts ":#{config['hostname']} SJOIN 1261978832 #{config['services-channel']} + :@OperServ"
sock.puts ":#{config['hostname']} SJOIN 1261978832 #{config['services-channel']} + :@Global"
sock.puts ":#{config['hostname']} SJOIN 1261978832 #{config['services-channel']} + :@MemoServ"
sock.puts ":#{config['hostname']} GLOBOPS :Finished synchronizing with network in -1 ms."

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
      sock.puts ":NickServ NOTICE #{args[0]} :Hey there."
    
    when '~' # timestamp, channel, list
      puts "Got user list for #{args[1]}: #{args[2]}"
      sock.puts ":#{config['hostname']} SJOIN #{args[0]} #{args[1]} + :@ChanServ"
    
    when ')' # channel, setter, when, topic
      puts "Topic for #{args[0]}: #{args.last}"
    
    when 'AO' # 10 1262304315 2309 MD5:1f93b28198e5c6a138cf22cf14883316 0 0 0 :Danopia
  
    when 'ES'
      puts "Server done syncing."
    
    when '9'
      puts "Server ponged."
    
    when '8'
      puts "Server pinged."
      sock.puts ":#{config['hostname']} 9 #{config['hostname']} :#{args.last}"
    
    when 'GLOBOPS'
      puts "Global op message: #{args.last}"
    
    when 'ERROR'
      puts "ERROR! #{args.first}"
      exit
  end
end
