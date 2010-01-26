require 'rubygems'
require 'net/ldap'

module LDAP
  def self.config= conf
    @config = conf
  end
  
  def self.base
    @config['base']
  end

  def self.ldap
    @ldap ||= create_ldap
  end
  
  def self.create_ldap
    ldap = Net::LDAP.new
    ldap.host = @config['hostname'] || 'localhost'
    ldap.port = (@config['port'] || 389).to_i
    ldap
  end
  
  #####################
  ## Prettifyng defs ##
  #####################
  
  def self.success?
    ldap.get_operation_result.code == 0
  end
  
  def self.search base, conditions=nil
    params = {:base => "#{base},#{self.base}"}
    if conditions
      conditions.each_pair do |key, value|
        filter = Net::LDAP::Filter.eq(key, value)
        params[:filter] = params[:filter] ? (params[:filter] & filter) : filter
      end
    end
    LDAP.ldap.search *params
  end
  
  ################
  ## Bind stuff ##
  ################
  
  def self.bind node=nil, pass=nil
    p node, pass
    ldap.auth "#{node},#{base}", pass
  end
  
  def self.user_bind username, password
    user_auth username, password
    ldap.bind
  end
  def self.user_auth username, password
    bind user_dn(username), password
  end
  
  def self.user_dn account, base=false
    @config['auth_pattern'].gsub('{username}', account) + (base ? ",#{base}" : '')
  end
  def self.bot_dn account, base=false
    @config['master_dn_pattern'].gsub('{username}', account) + (base ? ",#{base}" : '')
  end
  
  def self.bot_bind name
    name = name.nick if name.is_a? BitServ::ServicesBot
    name = name.downcase
    
    profile = @config['binds'].find {|profile| profile['bot'].downcase == name }
    
    username = profile['username'] || profile['bot']
    bind bot_dn(username), profile['password']
  end
end
