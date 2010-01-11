module BitServ
  class ChanServ < ServicesBot
    on :new_channel do |bot, link, channel|
      link.force_join channel, bot
      #stamps[args[1]] = args[0]
      #if args[1] == config['services-channel']
      #  (bots.keys - ['ChanServ']).each do |bot|
      #    sock.puts ":#{me} SJOIN #{args[0]} #{args[1]} + :@#{bot}"
      #  end
      #end
    end
  end
end
