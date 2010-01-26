require 'services'
require 'irb'

services = BitServ::Services.new 'bitserv.yaml'
LDAP.config = services.config['ldap']

IRB.start 
