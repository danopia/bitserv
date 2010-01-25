module BitServ
  class ChanServ < ServicesBot
    def on_new_channel channel
      @services.uplink.force_join channel, self
    end
    
    def on_shutdown message
      @services.uplink.quit_clone self.nick, 'Shutting down'
    end
  end
end
