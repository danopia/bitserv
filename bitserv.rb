require 'services'

services = BitServ::Services.new 'bitserv.yaml'
$services = services

trap "INT" do
  services.shutdown "Caught interupt"
  exit
end

EventMachine.run do
  services.run! # TODO: Have two different calls, one that connects and
  # one that starts EM and then connects. Possibly #connect to connect
  # the uplinks and #run! to run EventMachine.
end
