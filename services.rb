require 'yaml'

require 'user'
require 'channel'
require 'bot'

module BitServ
  class Services
    attr_accessor :bots, :config, :me, :uplink, :uplink_type, :hooks
    
    def running?
      @running
    end
    def run!
      return true if running?
      return false unless @uplink_type # TODO: error
      
      @running = true
      
      conf = @config['uplink']
      @uplink = EM.connect conf['hostname'], conf['port'], @uplink_type, self, conf
    end
    
    def initialize(config_file = nil)
      @config = YAML.load open(config_file)
      @me = @config['hostname']
      
      @bots = []
      @hooks = {}
      @running = false
      
      load_bots
    end
    
    def shutdown message='Shutting down'
      emit :on_shutdown, message
      @uplink.oper_msg message
    end
    
    def load_bots
      @config['bots'].each do |bot|
        require File.join(File.dirname(__FILE__), 'bots', bot['class'].downcase)
        @bots << BitServ.const_get(bot['class']).new(self) # (self, bot)
      end
    end
    
    def add_handler event, bot, &blck
      @hooks[event.to_sym] ||= []
      @hooks[event.to_sym] |= [bot] # hmm...
    end
    
    def emit event, *args
      return false unless @hooks.has_key? event.to_sym
      @hooks[event.to_sym].each do |bot|
        bot.send "on_#{event}", *args
      end
    end
    
    def is_services_channel? channel
      channel.name.downcase == @config['services-channel'].downcase
    end
    
    def uplink= type
      return false if running? # TODO: error
      @uplink_type = type
    end
  
    def introduce_clone nick, ident=nil, realname=nil, umodes='ioS'
      ident ||= nick
      realname ||= "Your friendly neighborhood #{nick}"
      @uplink.introduce_clone nick, ident, realname, umodes
    end
    
    def message origin, user, message
      user = user.nick if user.is_a? User # TODO: implement User#to_s?
      @uplink.message origin, user, format(message)
    end
    def notice origin, user, message
      user = user.nick if user.is_a? User # TODO: implement User#to_s?
      @uplink.notice origin, user, format(message)
    end
    
    def log origin, action, message
      message origin, @config['services-channel'], "#{action.upcase}: #{message}"
    end
    
    def format message
      message.gsub "^B", "\002"
    end
  end
end
