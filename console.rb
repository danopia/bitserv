require 'services'
require 'irb'

include BitServ

services = BitServ::Services.new 'bitserv.yaml'
LDAP.config = services.config['ldap']

IRB.start 
