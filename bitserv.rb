require 'user'
require 'channel'
require 'bot'

require 'services'

#require 'protocols/unrealircd'
require 'protocols/inspircd'

require 'bots/nickserv'
require 'bots/chanserv'
require 'bots/gitserv'
#require 'bots/relayserv'

services = BitServ::Services.new 'bitserv.yaml'
$services = services

services.load_bot BitServ::NickServ
services.load_bot BitServ::ChanServ
services.load_bot BitServ::GitServ
#services.load_bot BitServ::RelayServ

services.uplink = BitServ::Protocols::InspIRCd

trap "INT" do
  services.shutdown "Caught interupt"
  exit
end

EventMachine.run do
  services.run! # TODO: Have two different calls, one that connects and
  # one that starts EM and then connects. Possibly #connect to connect
  # the uplinks and #run! to run EventMachine.
end
