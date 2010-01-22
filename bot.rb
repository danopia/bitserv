module BitServ
  class ServicesBot
    attr_accessor :nick, :ident, :realname, :services, :uid, :timestamp
    
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
      @link = link
      
      params = message.split
      command = params.shift.downcase
      
      if command == 'help'
        cmd_help from, params # exception here because of the unlimited args
        
      elsif respond_to?("cmd_#{command}") && @@commands.has_key?(command.upcase)
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
      
      @link = nil
    end
    
    def cmd_help origin, args
      if args.size == 0
        notice origin, "****** ^B#{@nick} Help^B ******"
        
        file = File.join(File.dirname(__FILE__), 'help', @nick.downcase, 'synopsis') + '.txt'
        File.read(file).chomp.each_line do |line|
          notice origin, (line == '' ? '^B^B' : line)
        end
        
        notice origin, "^B^B"
        notice origin, "The following commands are available:"
        @@commands.each_pair do |cmd, data|
          next if data.has_key? :alias_of
          notice origin, "^B#{cmd.ljust 16}^B #{data[:description]}"
        end
        notice origin, "^B^B"
        
        notice origin, "***** ^BEnd of Help^B *****"
        
      elsif args.include? '..'
        notice origin, "You can stop hacking now."
        #notice origin, "No help available for ^B#{args.join ' '}^B."
        
      else
        file = File.join(File.dirname(__FILE__), 'help', @nick.downcase, *args) + '.txt'
        if File.exists? file
        
          notice origin, "****** ^B#{@nick} Help^B ******"
          notice origin, "Help for ^B#{args.join(' ').upcase}^B:"
          notice origin, "^B^B"
          
          File.read(file).chomp.each_line do |line|
            notice origin, (line == "\n" ? '^B^B' : line)
          end
          notice origin, "***** ^BEnd of Help^B *****"
          
        else
          notice origin, "No help available for ^B#{args.join ' '}^B."
        end
      end
    end
    
    def on_new_channel link, channel
      link.force_join channel, self if @services.is_services_channel? channel
    end
    
    def notice user, message, link=nil
      (link || @link).notice @nick, user, message.gsub("^B", "\002")
    end
    
    def log action, message
      @link.message @nick, @services.config['services-channel'], "#{action.upcase}: #{message.gsub "^B", "\002"}"
    end
  end
end
