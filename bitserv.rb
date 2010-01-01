require 'yaml'
config = YAML.load open('bitserv.yaml')

require 'socket'
sock = TCPSocket.new('localhost', 6667)

sock.puts "PASS #{config['uplink-password']}"
sock.puts "PROTOCTL TOKEN NICKv2 VHP NICKIP UMODE2 SJOIN SJOIN2 SJ3 NOQUIT TKLEXT"
sock.puts "SERVER services.danopia.net 1 :Atheme IRC Services"
sock.puts ":services.danopia.net KILL NickServ :services.danopia.net (Attempt to use service nick)"
sock.puts "NICK NickServ 1 1262302719 NickServ services.danopia.net services.danopia.net 0 +ioS * :Nickname Services"
sock.puts ":services.danopia.net KILL BotServ :services.danopia.net (Attempt to use service nick)"
sock.puts "NICK BotServ 1 1262302719 BotServ services.danopia.net services.danopia.net 0 +ioS * :Bot Services"
sock.puts ":services.danopia.net KILL ChanServ :services.danopia.net (Attempt to use service nick)"
sock.puts "NICK ChanServ 1 1262302719 ChanServ services.danopia.net services.danopia.net 0 +ioS * :Channel Services"
sock.puts ":services.danopia.net KILL OperServ :services.danopia.net (Attempt to use service nick)"
sock.puts "NICK OperServ 1 1262302719 OperServ services.danopia.net services.danopia.net 0 +ioS * :Operator Services"
sock.puts ":services.danopia.net KILL Global :services.danopia.net (Attempt to use service nick)"
sock.puts "NICK Global 1 1262302719 Global services.danopia.net services.danopia.net 0 +ioS * :Network Announcements"
sock.puts ":services.danopia.net KILL MemoServ :services.danopia.net (Attempt to use service nick)"
sock.puts "NICK MemoServ 1 1262302719 MemoServ services.danopia.net services.danopia.net 0 +ioS * :Memo Services"
sock.puts "PING :services.danopia.net"

sleep 0.5
sock.puts ":services.danopia.net SJOIN 1261978832 #services + :@NickServ"
sock.puts ":services.danopia.net SJOIN 1261978832 #services + :@BotServ"
sock.puts ":services.danopia.net SJOIN 1261978832 #services + :@ChanServ"
sock.puts ":services.danopia.net SJOIN 1261978832 #services + :@OperServ"
sock.puts ":services.danopia.net SJOIN 1261978832 #services + :@Global"
sock.puts ":services.danopia.net SJOIN 1261978832 #services + :@MemoServ"
sock.puts ":services.danopia.net GLOBOPS :Finished synchronizing with network in 134 ms."

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
      sock.puts ":services.danopia.net SJOIN #{args[0]} #{args[1]} + :@ChanServ"
    
    when ')' # channel, setter, when, topic
      puts "Topic for #{args[0]}: #{args.last}"
    
    when 'AO' # 10 1262304315 2309 MD5:1f93b28198e5c6a138cf22cf14883316 0 0 0 :Danopia
  
    when 'ES'
      puts "Server done syncing."
    
    when '9'
      puts "Server ponged."
    
    when '8'
      puts "Server pinged."
      sock.puts ":services.danopia.net 9 services.danopia.net :#{args.last}"
    
    when 'GLOBOPS'
      puts "Global op message: #{args.last}"
    
    when 'ERROR'
      puts "ERROR! #{args.first}"
      exit
  end
end
