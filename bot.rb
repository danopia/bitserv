module BitServ
  class ServicesBot
    attr_accessor :nick, :ident, :host, :type
    
    def self.commands
      @@commands ||= {}
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
    
    
    def initialize
      @nick = self.class.nick
    end
    
    def run_command origin, params
      return if params.empty?
      
      command = params.shift.upcase
      
      if command == 'HELP'
        $sock.puts ":NickServ ! #{origin} :****** \002#{@nick} Help\002 ******"
        $sock.puts ":NickServ ! #{origin} :\002\002"
        $sock.puts ":NickServ ! #{origin} :The following commands are available:"
        @@commands.each_pair do |cmd, data|
          $sock.puts ":NickServ ! #{origin} :\002#{cmd.ljust 16}\002#{data[:description]}"
        end
        $sock.puts ":NickServ ! #{origin} :\002\002"
        $sock.puts ":NickServ ! #{origin} :***** \002End of Help\002 *****"
        
      elsif @@commands.has_key? command
        data = @@commands[command]
        if data[:min_params] < params.size
          $sock.puts ":NickServ ! #{origin} :Insufficient parameters for \002#{command}\002."
          $sock.puts ":NickServ ! #{origin} :Syntax: #{command} <#{data[:params].join '> <'}>"
        else
          data[:block].call origin, params
        end
      
      else
        $sock.puts ":NickServ ! #{origin} :Invalid command. Use \002/msg #{@nick} help\002 for a command listing."
      end
          
    end
  end
end
