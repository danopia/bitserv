module BitServ
  class ChanServ < ServicesBot
    on :new_channel do |*args|
      p args
    end
  end
end
