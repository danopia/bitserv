require 'yaml'
require 'socket'

config = YAML.load open('bitserv.yaml')
$config = config
me = config['hostname']

require 'ldap'

require 'user'
require 'channel'
require 'bot'

require 'services'
require 'server_link'

require 'bots/nickserv'
require 'bots/chanserv'
require 'bots/gitserv'
#require 'bots/relayserv'

services = Services.new 'bitserv.yaml'
# TODO: Use Services#load_bot
services.bots = [BitServ::NickServ, BitServ::ChanServ, BitServ::GitServ]

EventMachine.run do
  services.run! # TODO: Have two different calls, one that connects and
  # one that starts EM and then connects. Possibly #connect to connect
  # the uplinks and #run! to run EventMachine.
end
