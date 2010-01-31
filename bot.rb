module BitServ
  class ServicesBot
    attr_accessor :nick, :ident, :realname, :services, :config, :uid, :timestamp
    
    def self.command names, description, *params, &blck
      @@commands ||= {}
      @@commands[self] ||= {}
      
      min_params = params.size
      min_params = params.shift if params.first.is_a? Fixnum
      
      data = {
        :description => description,
        :params => params,
        :min_params => min_params
      }
      
      names = [names] if names.is_a? String
      @@commands[self][names.first.upcase] = data
      
      if names.size > 1
        data = data.clone
        data[:alias_of] = names.shift.upcase
        names.each do |name|
          @@commands[self][name.upcase] = data
        end
      end
    end
    
    def initialize services, config
      @nick ||= config['nick'] || self.class.to_s.split('::').last
      @timestamp = Time.now.to_i
      
      @services = services
      @config = config
      @services.bots << self
      
      # Register hooks
      self.methods.each do |method|
        @services.add_handler $1, self if method =~ /^on_(.+)$/
      end
    end
    
    def on_priv_message from, bot, to, message
      return if (bot != self) || (to.downcase == self.nick.downcase)
      
      @@commands ||= {}
      @@commands[self.class] ||= {}
      
      params = message.split
      return if params.empty?
      command = params.shift.downcase
      
      if command == 'help'
        cmd_help from, params # exception here because of the unlimited args
        
      elsif @@commands[self.class].has_key?(command.upcase) && respond_to?("cmd_#{(@@commands[self.class][command.upcase][:alias_of] || command).downcase}")
        info = @@commands[self.class][command.upcase]
        if params.size < info[:min_params]
          notice from, "Insufficient parameters for ^B#{command}^B."
          notice from, "Syntax: #{command} <#{info[:params].join '> <'}>"
        else
          params.pop until params.size <= info[:params].size
          send "cmd_#{(@@commands[self.class][command.upcase][:alias_of] || command).downcase}", from, *params
        end
        
      else
        p respond_to?("cmd_#{command}")
        p @@commands[self.class].has_key?(command.upcase)
        notice from, "Invalid command. Use ^B/msg #{@nick} help^B for a command listing."
      end
      
      @link = nil
    end
    
    def cmd_help origin, args
      if args.size == 0
        notice origin, "****** ^B#{@nick} Help^B ******"
        notice origin, load_help(['synopsis'])
        notice origin, "^B^B"
        notice origin, "The following commands are available:"
        @@commands[self.class].each_pair {|cmd, data|
          next if data.has_key? :alias_of
          notice origin, "^B#{cmd.ljust 16}^B #{data[:description]}"
        }
        notice origin, "^B^B"
        notice origin, "***** ^BEnd of Help^B *****"
        
      elsif have_help? args
        notice origin, "****** ^B#{@nick} Help^B ******"
        notice origin, "Help for ^B#{args.join(' ').upcase}^B:"
        notice origin, "^B^B"
        notice origin, load_help(args)
        notice origin, "***** ^BEnd of Help^B *****"
      else
        notice origin, "No help available for ^B#{args.join ' '}^B."
      end
    end
    
    def help_path args
      return false if args.include? '..'
      args.map! {|piece| piece.downcase }
      File.join(File.dirname(__FILE__), 'help', @nick.downcase, *args) + '.txt'
    end
    def have_help? args
      File.exists? help_path(args)
    end
    def load_help args
      return File.read(help_path(args)) if have_help? args
      "No help available for ^B#{args.join ' '}^B."
    end
    
    def on_new_channel  channel
      @services.uplink.force_join channel, self if @services.is_services_channel? channel
    end
    
    def notice user, message
      @services.uplink.notice self, user, message.gsub("^B", "\002")
    end
    
    def log action, message
      @services.uplink.message self, @services.config['services-channel'], "#{action.upcase}: #{message.gsub "^B", "\002"}"
    end
  end
end
