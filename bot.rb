module BitServ
  class ServicesBot
    attr_accessor :nick, :ident, :realname, :services
    
    def self.command names, description, *params, &blck
      @@commands ||= {}
      
      min_params = params.size
      min_params = params.shift if params.first.is_a? Fixnum
      
      data = {
        :description => description,
        :params => params,
        :min_params => min_params
      }
      
      names = [names] if names.is_a? String
      @@commands[names.first.upcase] = data
      
      if names.size > 1
        data = data.clone
        data[:alias_of] = names.shift.upcase
        names.each do |name|
          @@commands[name.upcase] = data
        end
      end
    end
    
    def initialize services
      @nick ||= self.class.to_s.split('::').last
      
      @services = services
      @services.introduce_clone self.nick
      
      # Register hooks
      self.methods.each do |method|
        @services.add_handler $1, self if method =~ /^on_(.+)$/
      end
    end
    
    def on_priv_message link, from, to, message
      return unless to.downcase == self.nick.downcase
      
      params = message.split
      command = params.shift
      if respond_to?("cmd_#{command}") && @@commands.has_key?(command.upcase)
        info = @@commands[command.upcase]
        if params.size < info[:min_params]
          notice from, "Insufficient parameters for ^B#{command}^B."
          notice from, "Syntax: #{command} <#{info[:params].join '> <'}>"
        else
          params.pop until params.size <= info[:params].size
          send "cmd_#{command}", from, *params
        end
      else
        p respond_to?("cmd_#{command}")
        p @@commands.has_key?(command.upcase)
        notice from, "Invalid command. Use ^B/msg #{@nick} help^B for a command listing."
      end
    end
    
    def on_new_channel link, channel
      link.force_join channel, self if @services.is_services_channel? channel
    end
    
    # TODO: Extremely broken/unusable
    def self.run_command origin, params
      return if params.empty?
      
      command = params.shift.upcase
      
      if command == 'HELP'
        notice origin, "****** ^B#{@nick} Help^B ******"
        notice origin, "^B^B"
        notice origin, "The following commands are available:"
        self.class.commands.each_pair do |cmd, data|
          next if data.has_key? :alias_of
          notice origin, "^B#{cmd.ljust 16}^B #{data[:description]}"
        end
        notice origin, "^B^B"
        notice origin, "***** ^BEnd of Help^B *****"
        
      elsif self.class.commands.has_key? command
        data = self.class.commands[command]
        if data[:min_params] > params.size
          notice origin, "Insufficient parameters for ^B#{command}^B."
          notice origin, "Syntax: #{command} <#{data[:params].join '> <'}>"
        else
          data[:block].call origin, params
        end
      
      else
        notice origin, "Invalid command. Use ^B/msg #{@nick} help^B for a command listing."
      end
          
    end
    
    def notice user, message
      link.notice @nick, user, message.gsub("^B", "\002")
    end
    
    def log action, message
      link.message @nick, @services.config['services-channel'], "#{action.upcase}: #{message.gsub "^B", "\002"}"
    end
  end
end
