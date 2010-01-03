require 'yaml'
require 'socket'

config = YAML.load open('bitserv.yaml')
$config = config
me = config['hostname']

require 'ldap'

require 'user'
require 'channel'
require 'bot'

require 'server_link'

require 'bots/nickserv'
require 'bots/chanserv'
require 'bots/gitserv'
require 'bots/relayserv'

bots = [BitServ::NickServ, BitServ::ChanServ, BitServ::GitServ]

EventMachine.run do
  uplink = config['uplink']
  $uplink = EM.connect uplink['hostname'], uplink['port'].to_i, BitServ::ServerLink, config, config['uplink'], bots
  # TODO: The uplink won't manage bots, the Services instance will
end
