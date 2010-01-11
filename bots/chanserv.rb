module BitServ
  class ChanServ < ServicesBot
    def on_new_channel link, channel
      link.force_join channel, self
      #stamps[args[1]] = args[0]
      #if args[1] == config['services-channel']
      #  (bots.keys - ['ChanServ']).each do |bot|
      #    sock.puts ":#{me} SJOIN #{args[0]} #{args[1]} + :@#{bot}"
      #  end
      #end
    end
  end
end
