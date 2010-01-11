module BitServ
  class ChanServ < ServicesBot
    def on_new_channel link, channel
      link.force_join channel, self
    end
    
    def on_shutdown message
      @services.call_uplinks :quit_clone, self.nick, 'Shutting down'
    end
  end
end
