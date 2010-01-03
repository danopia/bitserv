require 'yaml'
require 'socket'

require 'rubygems'
require 'net/ldap'

config = YAML.load open('bitserv.yaml')
$config = config
me = config['hostname']


module LDAP
  Config = $config['ldap']
  
  def self.base
    Config['base']
  end

  def self.ldap
    @ldap ||= create_ldap
  end
  
  def self.create_ldap
    ldap = Net::LDAP.new
    ldap.host = Config['hostname'] || 'localhost'
    ldap.port = (Config['port'] || 389).to_i
    ldap
  end
  
  def self.bind node=nil, pass=nil
    ldap.auth "#{node},#{base}", pass
  end
  
  def self.user_bind username, password
    user_auth username, password
    ldap.bind
  end
  def self.user_auth username, password
    bind Config['auth_pattern'].gsub('{username}', username), password
  end
  
  # Don't need to bind; just increases operation time
  def self.master_bind
    bind Config['master_bind']['node'], Config['master_bind']['password']
  end
  
  def self.success?
    ldap.get_operation_result.code == 0
  end
end

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
