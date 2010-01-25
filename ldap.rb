require 'rubygems'
require 'net/ldap'

module LDAP
  def self.base
    $services.config['base']
  end

  def self.ldap
    @ldap ||= create_ldap
  end
  
  def self.create_ldap
    ldap = Net::LDAP.new
    ldap.host = $services.config['ldap']['hostname'] || 'localhost'
    ldap.port = ($services.config['ldap']['port'] || 389).to_i
    ldap
  end
  
  def self.success?
    ldap.get_operation_result.code == 0
  end
  
  ################
  ## Bind stuff ##
  ################
  
  def self.bind node=nil, pass=nil
    ldap.auth "#{node},#{base}", pass
  end
  
  def self.user_bind username, password
    user_auth username, password
    ldap.bind
  end
  def self.user_auth username, password
    bind $services.config['ldap']['auth_pattern'].gsub('{username}', username), password
  end
  
  def self.bot_bind name
    name = name.class.name.to_s.split('::').last if name.is_a? BitServ::ServicesBot
    name = name.downcase
    
    profile = $services.config['ldap']['binds'].find {|profile| profile['bot'].downcase == name }
    
    username = profile['username'] || profile['bot']
    bind $services.config['ldap']['master_dn_pattern'].gsub('{username}', username), profile['password']
  end
end
