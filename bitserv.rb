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
  end
  
  def self.user_bind username, password
    user_bind username, password
    ldap.bind
  end
  def self.user_auth username, password
    bind Config['auth_pattern'].gsub('{username}', username), password
  end
  
  # Don't need to bind; just increases operation time
  def self.master_bind
    bind Config['master_bind']['node'], Config['master_bind']['password']
  end
  
  def self.success?
    ldap.get_operation_result.code == 0
  end
end


sock = TCPSocket.new(config['uplink']['hostname'], config['uplink']['port'].to_i)
$sock = sock

require 'user'
require 'channel'
require 'bot'

require 'bots/nickserv'
require 'bots/chanserv'
require 'bots/gitserv'

bots = {
  'nickserv' => BitServ::NickServ.new,
  'chanserv' => BitServ::ChanServ.new,
  'gitserv' => BitServ::GitServ.new,
}

users = {}

sock.puts "PASS #{config['uplink']['password']}"
sock.puts "PROTOCTL TOKEN NICKv2 VHP NICKIP UMODE2 SJOIN SJOIN2 SJ3 NOQUIT TKLEXT"
sock.puts "SERVER #{me} 1 :#{config['description']}"

bots.each_key do |bot|
  sock.puts ":#{me} KILL #{bot} :#{me} (Attempt to use service nick)"
  sock.puts "& #{bot} 1 #{Time.now.to_i} #{bot} #{me} #{me} 0 +ioS * :Your standard #{bot}, minus any features"
end

stamps = {}

sock.puts "8 :#{me}"

joined_chan = false

while data = sock.gets
  puts data
  
  parts = data.chomp.split ' :', 2
  args = parts.shift.split ' '
  args << parts.shift if parts.any?
  
  origin = nil
  origin = args.shift[1..-1] if args.first[0,1] == ':'
  origin = users[origin] if origin && users.has_key?(origin)
  
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
             # if origin: new nick, timestamp (where origin is old nick)
      if origin
        users.delete origin.nick
        origin.nick = args.shift
        origin.timestamp = Time.at(args.shift.to_i)
      else
        origin = BitServ::User.new args.shift
        
        origin.numeric = args.shift.to_i
        origin.timestamp = Time.at(args.shift.to_i)
        origin.ident = args.shift
        origin.ip = args.shift
        origin.server = args.shift
        origin.hops = args.shift.to_i
        origin.modes = args.shift
        origin.cloak = args.shift
        origin.base64 = args.shift
        origin.realname = args.shift
      end
      
      users[origin.nick] = origin
      
    when ',' # quit: message
      origin.quit args.shift
      users.delete origin.nick
    
    when '~' # timestamp, channel, list
      puts "Got user list for #{args[1]}: #{args[2]}"
      sock.puts ":#{me} SJOIN #{args[0]} #{args[1]} + :@ChanServ" unless stamps[args[1]]
      stamps[args[1]] = args[0]
      if args[1] == config['services-channel']
        (bots.keys - ['ChanServ']).each do |bot|
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
      
      bots[args[0].downcase].run_command origin, args[1].split if bots.has_key? args[0].downcase
    
    when 'AO' # 10 1262304315 2309 MD5:1f93b28198e5c6a138cf22cf14883316 0 0 0 :Danopia
      
    
    when 'ES'
      unless joined_chan
        sock.puts ":#{me} ~ #{Time.now.to_i} #{config['services-channel']} :@#{bots.keys.join ' @'}"
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
