require 'user'
require 'channel'
require 'bot'

require 'services'

#require 'protocols/unrealircd'
require 'protocols/inspircd'

services = BitServ::Services.new 'bitserv.yaml'
$services = services

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
