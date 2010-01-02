require 'rubygems'
require 'on_irc'

module BitServ
  class RelayServ < ServicesBot
    attr_accessor :nicks
    
    def self.deping nick
      "#{nick[0,2]}\342\200\213#{nick[2..-1]}"
    end
    
    def self.bot
      @@bot ||= nil
    end
    
    def initialize *args
      super
      
      @nicks = []
      
      @@bot = IRC.new do
        nick 'relay'
        ident 'on_irc'
        realname 'on_irc Ruby IRC library - illusion relay'

        server :eighthbit do
          address 'irc.eighthbit.net'
        end
      end

      @@bot.on '001' do
        join '#illusion'
      end

      @@bot.on :privmsg do
        begin
          next unless params[0] == '#illusion'
          
          $nicks ||= []
          unless $nicks.include? sender.nick
            $sock.puts ":services.danopia.net KILL #{sender.nick}[8b] :services.danopia.net (Attempt to use service nick)"
            $sock.puts "& #{sender.nick}[8b] 1 #{Time.now.to_i} #{sender.nick}[8b] services.danopia.net services.danopia.net 0 +ioS * :Person from EighthBit"
            $sock.puts ":services.danopia.net ~ #{Time.now.to_i} #bits :#{sender.nick}[8b]"
            $nicks << sender.nick
          end
          
          $sock.puts ":#{sender.nick}[8b] ! #bits :#{params[1]}"
        rescue => ex
          puts ex.class, ex.message, ex.backtrace
        end
      end

      @@bot.on :ping do
        pong params[0]
      end

      @@bot.on :all do
        p = "(#{sender}) " unless sender.empty?
        puts "#{server.name}: #{p}#{command} #{params.inspect}"
      end
      
      Thread.new { @@bot.connect }
    end
  end
end
