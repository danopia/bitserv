module BitServ
  class ServicesBot
    attr_accessor :nick, :ident, :realname, :services
    
    def initialize services
      @nick ||= self.class.to_s.split('::').last
      
      @services = services
      @services.introduce_clone self.nick
      
      # Register hooks
      self.methods.each do |method|
        @services.on $1, self if method =~ /^on_(.+)$/
      end
      
      @@commands ||= {}
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
    
    #def self.notice user, message
      #user = user.nick if user.is_a? User # TODO: implement User#to_s?
      #$sock.puts ":#{@nick} B #{user} :#{message.gsub "^B", "\002"}"
    #end
    
    #def self.log action, message
      #$sock.puts ":#{@nick} ! #{$config['services-channel']} :#{action.upcase}: #{message.gsub "^B", "\002"}"
    #end
  end
end
