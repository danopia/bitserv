module BitServ
  class ServicesBot
    attr_accessor :nick, :ident, :host, :type
    
    def self.commands
      @commands ||= {}
    end
    def self.handlers
      @handlers ||= {}
    end
    
    def self.nick(nick=nil)
      if nick
        @nick = nick # DSL set
      else
        @nick ||= self.name.to_s # get
      end
    end
    
    def self.command names, description, *params, &blck
      min_params = params.size
      min_params = params.shift if params.first.is_a? Fixnum
      
      data = {
        :description => description,
        :params => params,
        :min_params => min_params,
        :block => blck
      }
      
      names = [names] if names.is_a? String
      names.each do |name|
        commands[name.upcase] = data
      end
    end
    
    def self.on event, &blck
      handlers[event.to_sym] = blck
    end
    
    def initialize
      @nick = self.class.nick.split('::').last
    end
    
    def emit event, args
      handlers[event.to_sym].call args if handlers.has_key? event.to_sym
    end
    
    def run_command origin, params
      return if params.empty?
      
      command = params.shift.upcase
      
      if command == 'HELP'
        $sock.puts ":#{@nick} B #{origin} :****** \002#{@nick} Help\002 ******"
        $sock.puts ":#{@nick} B #{origin} :\002\002"
        $sock.puts ":#{@nick} B #{origin} :The following commands are available:"
        self.class.commands.each_pair do |cmd, data|
          $sock.puts ":#{@nick} B #{origin} :\002#{cmd.ljust 16}\002#{data[:description]}"
        end
        $sock.puts ":#{@nick} B #{origin} :\002\002"
        $sock.puts ":#{@nick} B #{origin} :***** \002End of Help\002 *****"
        
      elsif self.class.commands.has_key? command
        data = self.class.commands[command]
        if data[:min_params] > params.size
          $sock.puts ":#{@nick} B #{origin} :Insufficient parameters for \002#{command}\002."
          $sock.puts ":#{@nick} B #{origin} :Syntax: #{command} <#{data[:params].join '> <'}>"
        else
          data[:block].call origin, params
        end
      
      else
        $sock.puts ":#{@nick} B #{origin} :Invalid command. Use \002/msg #{@nick} help\002 for a command listing."
      end
          
    end
  end
end
