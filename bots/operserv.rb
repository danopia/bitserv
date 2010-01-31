module BitServ
  class OperServ < ServicesBot
    command 'reload', 'Reloads the services.'
    
    def cmd_reload origin
      load 'account.rb'
      load 'bot.rb'
      load 'channel.rb'
      load 'connection.rb'
      load 'ldap.rb'
      load 'services.rb'
      load 'user.rb'
      
      load 'bots/chanserv.rb'
      load 'bots/gitserv.rb'
      load 'bots/groupserv.rb'
      load 'bots/nickserv.rb'
      load 'bots/operserv.rb'
      
      load 'protocols/inspircd.rb'
    end
  end
end
