require 'yaml'

require 'user'
require 'channel'
require 'bot'

require 'server_link'

module BitServ
  class Services
    attr_accessor :bots, :config, :me, :uplinks, :hooks
    
    def running?
      @running
    end
    def run!
      @running = true
      connect_uplinks
    end
    
    def initialize(config_file = nil)
      @config = YAML.load open(config_file)
      @me = @config['hostname']
      
      @bots = []
      @uplinks = []
      @hooks = {}
      @running = false
    end
    
    def load_bot type, *args
      @bots << type.new(self, *args)
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
    
    def add_uplink type, name=nil
      uplink = config['uplink']
      uplink ||= config['uplinks'].find {|block| block['name'] == name}
      info = {
        :name => uplink['name'] || 'main',
        :host => uplink['hostname'],
        :port => uplink['port'].to_i,
        :type => type,
        :pass => uplink['password'],
      }
      @uplinks << info
      connect_uplink info if running?
    end
    
    def connect_uplinks
      @uplinks.each do |uplink|
        connect_uplink uplink
      end
    end
    
    def connect_uplink uplink
      uplink[:instance] = EM.connect uplink[:host], uplink[:port], uplink[:type], self, uplink
    end
    
    def call_uplinks method, *args
      @uplinks.each do |uplink|
        uplink.call method, *args
      end
    end
  
    def introduce_clone nick, ident=nil, realname=nil, umodes='ioS'
      ident ||= nick
      realname ||= "Your friendly neighborhood #{nick}"
      call_uplinks :introduce_clone, nick, ident, realname, umodes
    end
    
    def message origin, user, message
      user = user.nick if user.is_a? User # TODO: implement User#to_s?
      call_uplinks :message, origin, user, format(message)
    end
    def notice origin, user, message
      user = user.nick if user.is_a? User # TODO: implement User#to_s?
      call_uplinks :notice, origin, user, format(message)
    end
    
    def log origin, action, message
      message origin, @config['services-channel'], "#{action.upcase}: #{message}"
    end
    
    def format message
      message.gsub "^B", "\002"
    end
  end
end
