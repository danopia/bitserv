require 'connection'
require 'user'

module BitServ
module Protocols
class InspIRCd < LineConnection
  attr_accessor :users, :channels, :servers, :uplink, :bots, :services, :config, :nicks

  def initialize services, config
    super()
    
    @users = {}
    @channels = {}
    @services = services
    @config = config
    
    @me = '00B' # TODO: user a config
    @uplink = nil
    @servers = {}
    @servers[@me] = services.config['hostname']
    
    @next_uid = 'AAAAAA'
    @bots = []
    @nicks = []
    
  rescue => ex
    puts ex.class, ex.message, ex.backtrace
    raise ex
  end
  
  def bot_uid bot
    if info = @bots.rassoc(bot)
      info.first
    else
      uid = next_uid
      @bots << [uid, bot]
      uid
    end
  end
  
  def next_uid
    val = @next_uid.clone
    @next_uid.succ!
    "#{@me}#{val}"
  end
  
  def uid_bot uid
    if info = @bots.assoc(uid)
      info.last
    else
      nil
    end
  end
  
  def send *args
    args = args.flatten # indirect clone, I hope
    args.unshift ":#{args.shift.nick}" if args.first.is_a? User
    args[(args.first[0,1] == ':') ? 1 : 0].upcase!
    args.push ":#{args.pop}" if args.last.to_s.include? ' '
    puts "Sent #{args.join ' '}"
    send_line args.join ' '
  end
  
  def send_from origin, *args
    origin = origin.nick if origin.is_a? User
    origin = origin.uid if origin.is_a? ServicesBot
    args.unshift ":#{origin}"
    send *args
  end
  
  def send_from_me *args
    send_from @me, *args
  end
  
  def send_handshake
    send 'server', @servers[@me], @config[:pass], 0, @me, @services.config['description']
  end
  
  def ping
    send_from_me 'ping', @me, @uplink
  end
  
  def oper_msg message
    #send_from @me, 'GLOBOPS', message
  end
  
  def force_join channel, bot
    send_from_me 'fjoin', channel.name, channel.timestamp.to_i, '+', "o,#{bot_uid bot}"
  end
  
  def introduce_clone uid, ts, nick, ident=nil, realname=nil, umodes='io'
    ident ||= nick
    realname ||= "Your friendly neighborhood #{nick}"
    
    send_from_me 'uid', uid, ts, nick, @servers[@me], @servers[@me], ident, '0.0.0.0', ts, "+#{umodes}", realname
    send_from uid, 'opertype', 'Services'
  end
  
  def introduce_bot bot
    bot.uid ||= bot_uid(bot)
    introduce_clone bot.uid, bot.timestamp, bot.nick
  end
  
  def send_burst
    send_from_me 'burst'
    send_from_me 'version', "bitserv-0.0.1. #{@me} adFljRn" # TODO: Dynamic version!
    introduce_bots
    send_from_me 'endburst'
  end
  
  def introduce_bots
    @services.bots.each do |bot|
      introduce_bot bot
    end
  end
  
  def quit_clone nick, message='Leaving'
    send_from nick, 'QUIT', message
  end
    
  def message origin, user, message
    user = user.nick if user.is_a? User # TODO: implement User#to_s?
    send_from origin, 'privmsg', user, message
  end
  def notice origin, user, message
    user = user.nick if user.is_a? User # TODO: implement User#to_s?
    send_from origin, 'notice', user, message
  end
  
  # Shifts +self+ onto the argument list and passes it to the associated
  # Services instance.
  def emit event, *args
    @services.emit event, self, *args
  end
  
  def receive_line line
    super # prints the data
    
    return if line.size < 1
    parts = line.split ' :', 2
    args = parts.shift.split ' '
    args << parts.shift if parts.any?
    
    origin = nil
    origin = args.shift[1..-1] if args.first[0,1] == ':'
    origin = @users[origin] if origin && @users.has_key?(origin)
    
    command = args.shift
    case command
        
      when 'NOTICE'
        puts args.last
      
      when 'CAPAB'
        send_handshake if args.first == 'END'
      
      # TODO: This will FAIL when there are multiple servers on the uplink network!
      when 'SERVER' # server, numeric, description
        unless @uplink
          @uplink = args[3]
          @servers[@uplink] = args[0]
          
          send_burst
          ping
        end
        
        puts "New server: #{args[4]}"
      
      when 'SMO'
        puts "Server message to #{args[0]}: #{args[1]}"
      
      when 'UID'
        if origin.is_a? User
          old_nick = origin.nick
          origin.nick = args.shift
          origin.timestamp = Time.at(args.shift.to_i)
          
          emit :nick_change, old_nick, origin
        else
          origin = BitServ::User.new args[2]
          origin.server = origin
          
          origin.uid = args.shift
          args.shift # connect time. # origin.timestamp = Time.at(args.shift.to_i)
          args.shift # nick
          origin.hostname = args.shift
          origin.cloak = args.shift
          origin.ident = args.shift
          origin.ip = args.shift
          origin.timestamp = Time.at(args.shift.to_i)
          origin.modes = args.shift
          origin.realname = args.shift
          
          @users[origin.uid] = origin
          
          emit :new_client, origin
        end
        
      when 'QUIT' # quit: message
        emit :client_quit, origin, args.shift
        @users.delete origin.nick
      
      when 'FJOIN' # timestamp, channel, list
        puts "Got user list for #{args[0]}: #{args[3]}"
        
        channel = @channels[args[0].downcase]
        if channel
          channel.users += args[3].split(' ')
          channel.timestamp = Time.at args[1].to_i
          
          emit :channel_join, channel, args[3].split(' ')
        else
          channel = Channel.new args[0]
          channel.users += args[3].split(' ')
          channel.timestamp = Time.at args[1].to_i
          
          @channels[args[0].downcase] = channel
          
          emit :new_channel, channel
        end
      
      when 'H' # kick; channel, kickee, message
        puts "#{origin} kicked #{args[1]} from #{args[0]} (#{args[2]})"
        emit :client_kicked, origin, *args
        
        # TODO: Make this a hook too.
        #if args[1] == 'ChanServ'
        #  sock.puts ":#{me} SJOIN #{stamps[args[0]]} #{args[0]} + :@ChanServ"
        #  sock.puts ":ChanServ H #{args[0]} #{origin} :REVENGEEEEE!"
        #end
      
      when ')' # channel, setter, when, topic
        puts "Topic for #{args[0]}: #{args.last}"
        emit :got_topic, *args
      
      when 'PRIVMSG' # channel, message
        puts "#{origin} said on #{args[0]}: #{args[1]}"
        
        if args[0][0,1] == '#'
          emit :chan_message, origin, *args
        else
          bot = uid_bot(args.first) || args.first
          emit :priv_message, origin, bot, *args
        end
        
        #if args[1] =~ /^\001ACTION kicks ChanServ/
        #  sock.puts ":ChanServ ! #{args[0]} :ow"
        #end
        
        #if args[0] == '#bits'
        #  BitServ::RelayServ.bot[:eighthbit].send_cmd(:privmsg, '#illusion', "<#{BitServ::RelayServ.deping origin.nick}> #{args[1]}")
        #end
        
        # TODO: Do something about this.
        #bots[args[0].downcase].run_command origin, args[1].split if bots.has_key? args[0].downcase
        
      when 'NOTICE' # notice: channel, message
        if args[0][0,1] == '#'
          emit :chan_notice, origin, *args
        else
          bot = uid_bot(args.first) || args.first
          emit :priv_notice, origin, bot, *args
        end
      
      when 'AO' # 10 1262304315 2309 MD5:1f93b28198e5c6a138cf22cf14883316 0 0 0 :Danopia
        # TODO: Find out what this is. No idea, but it might be opering?
      
      when 'ES'
        #~ unless joined_chan
          #~ sock.puts ":#{me} ~ #{Time.now.to_i} #{config['services-channel']} :@#{bots.keys.join ' @'}"
          #~ joined_chan = true
        #~ end
        
        send_from @me, 'globops', 'Finished synchronizing with network in -0.01 ms.' # TODO: Use a method (it exists)
        puts "Done syncing."
      
      when '9'
        puts "Server ponged."
      
      when '8'
        puts "Server pinged."
        send_from @me, '9', @me, args
      
      when 'GLOBOPS'
        puts "Global op message: #{args.last}"
      
      when 'ERROR'
        puts "ERROR! #{args.first}"
        
      else
        puts "Unknown packet"#: #{line}"
    end
  end
end # class UnrealIRCd
end # module Protocols
end # module BitServ
