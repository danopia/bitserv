#!/usr/bin/env ruby
require 'rubygems'
require 'on_irc'

bot = IRC.new do
  nick 'illusion-relay'
  ident 'on_irc'
  realname 'on_irc Ruby IRC library - illusion relay'

  server :eighthbit do
    address 'irc.eighthbit.net'
  end

  server :testnet do
    address 'danopia.no-ip.org'
  end
end


bot[:eighthbit].on '001' do
  join '#illusion'
end

bot[:testnet].on '001' do
  join '#bits'
end

def deping nick
  "#{nick[0,2]}\342\200\213#{nick[2..-1]}"
end

bot[:eighthbit].on :privmsg do
  bot[:testnet].send_cmd(:privmsg, '#bits', "<#{deping sender.nick}> #{params[1]}") if params[0] == '#illusion'
end

bot[:testnet].on :privmsg do
  bot[:eighthbit].send_cmd(:privmsg, '#illusion', "<#{deping sender.nick}> #{params[1]}") if params[0] == '#bits'
end

bot.on :ping do
  pong params[0]
end

bot.on :all do
  p = "(#{sender}) " unless sender.empty?
  puts "#{server.name}: #{p}#{command} #{params.inspect}"
end

bot.connect
