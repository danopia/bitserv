require 'connection'
require 'user'

module BitServ
class ServerLink < LineConnection
  attr_accessor :users, :remote_server, :protocols, :me, :uplink, :config
  
  DEFAULT_PROTOCOLS = 'PROTOCTL TOKEN NICKv2 VHP NICKIP UMODE2 SJOIN SJOIN2 SJ3 NOQUIT TKLEXT'

  def initialize config, uplink
    super()
    
    @users = {}
    @protocols = (config['protocols'] || DEFAULT_PROTOCOLS).split ' '
    @me = config['hostname'] # TODO: Services instance
    @uplink = uplink
    @config = config
    
    send_welcome
  #rescue => ex
  #  puts ex.class, ex.message, ex.backtrace
  end
  
  def send *args
    args = args.flatten # indirect clone, I hope
    args.unshift ":#{args.shift.nick}" if args.first.is_a? User
    args[(args.first[0,1] == ':') ? 1 : 0].upcase!
    args.push ":#{args.pop}" if args.last.include? ' '
    send_line args.join ' '
  end
  
  def send_welcome
    send 'pass', @uplink['password']
    send 'protoctl', @protocols
    send 'server', @me, 1, @config['description']

    # TODO: Use the Services#bots array
    #bots.each_key do |bot|
    #  sock.puts ":#{me} KILL #{bot} :#{me} (Attempt to use service nick)"
    #  sock.puts "& #{bot} 1 #{Time.now.to_i} #{bot} #{me} #{me} 0 +ioS * :Your standard #{bot}, minus any features"
    #end

    send '8', @me # ping. TODO: put in a ping def?
  end
  
  def receive_line line
    super # prints the data
    
    parts = line.split ' :', 2
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
      
      when '&' # nick, server numeric?, timestamp, ident, ip, server, servhops?, umode, cloak, base64, realname
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
      
      when '~' # timestamp, channel, list TODO: parse into a Channel object
        puts "Got user list for #{args[1]}: #{args[2]}"
        
        # TODO: Use bot hooks instead of these hackity hacks
        #sock.puts ":#{me} SJOIN #{args[0]} #{args[1]} + :@ChanServ" unless stamps[args[1]]
        #stamps[args[1]] = args[0]
        #if args[1] == config['services-channel']
        #  (bots.keys - ['ChanServ']).each do |bot|
        #    sock.puts ":#{me} SJOIN #{args[0]} #{args[1]} + :@#{bot}"
        #  end
        #end
      
      when 'H' # kick; channel, kickee, message
        puts "#{origin} kicked #{args[1]} from #{args[0]} (#{args[2]})"
        
        # TODO: Make this a hook too.
        #if args[1] == 'ChanServ'
        #  sock.puts ":#{me} SJOIN #{stamps[args[0]]} #{args[0]} + :@ChanServ"
        #  sock.puts ":ChanServ H #{args[0]} #{origin} :REVENGEEEEE!"
        #end
      
      when ')' # channel, setter, when, topic
        puts "Topic for #{args[0]}: #{args.last}"
      
      when '!' # channel, message
        puts "#{origin} said on #{args[0]}: #{args[1]}"
        
        #if args[1] =~ /^\001ACTION kicks ChanServ/
        #  sock.puts ":ChanServ ! #{args[0]} :ow"
        #end
        
        if args[0] == '#bits'
          BitServ::RelayServ.bot[:eighthbit].send_cmd(:privmsg, '#illusion', "<#{BitServ::RelayServ.deping origin.nick}> #{args[1]}")
        end
        
        # TODO: Do something about this.
        bots[args[0].downcase].run_command origin, args[1].split if bots.has_key? args[0].downcase
      
      when 'AO' # 10 1262304315 2309 MD5:1f93b28198e5c6a138cf22cf14883316 0 0 0 :Danopia
        # No idea, but it might be opering?
      
      when 'ES'
        #~ unless joined_chan
          #~ sock.puts ":#{me} ~ #{Time.now.to_i} #{config['services-channel']} :@#{bots.keys.join ' @'}"
          #~ joined_chan = true
        #~ end
        
        send ":#{@me}", 'globops', 'Finished synchronizing with network in -0.01 ms.'
        puts "Done syncing."
      
      when '9'
        puts "Server ponged."
      
      when '8'
        puts "Server pinged."
        send ":#{@me}", '9', @me, args
      
      when 'GLOBOPS'
        puts "Global op message: #{args.last}"
      
      when 'ERROR'
        puts "ERROR! #{args.first}"
        
      else
        puts "Unknown packet"#: #{line}"
    end
  end
end
end
