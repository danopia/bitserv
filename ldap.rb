require 'rubygems'
require 'net/ldap'

class Net::LDAP::Entry
  def inspect
    "#{dn}: " + @myhash.map {|(key,value)|
      next if key == :dn
      "#{key}: #{(value.size == 1 ? value.first : value).inspect}"
    }.compact.join(', ')
  end
  
  def pretty_print q
    @myhash.pretty_print q
  end
end

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
  
  def self.search base, conditions=nil, params={}
    params[:base] = base
    
    if conditions
      params[:filter] = Net::LDAP::Filter.eq *conditions.shift
      conditions.each_pair do |key, value|
        params[:filter] &= Net::LDAP::Filter.eq(key, value)
      end
    end
    
    ldap.search(params) || []
  end
  
  def self.first *params
    entries = search *params
    return nil if entries.empty?
    entries.first
  end
  
  def self.select dn, params={}
    params[:scope] = Net::LDAP::SearchScope_BaseObject
    first dn, nil, params
  end
  
  def self.exists? dn, params={}
    params[:scope] = Net::LDAP::SearchScope_BaseObject
    params[:return_result] = false
    search dn, nil, params
    success?
  end
  
  def self.delete dn
    ldap.delete :dn => dn
  end
  
  def self.create dn, attrs
    ldap.add :dn => dn, :attributes => attrs
  end
  
  ################
  ## Bind stuff ##
  ################
  
  def self.bind node=nil, pass=nil
    ldap.auth node, pass
  end
  
  def self.check_bind
    ldap.bind
  end
  
  def self.user_dn account
    @config['auth_pattern'].gsub('{username}', account) + ",#{base}"
  end
  def self.bot_dn account
    @config['master_dn_pattern'].gsub('{username}', account) + ",#{base}"
  end
  
  def self.user_bind username, password
    bind user_dn(username), password
  end
  def self.bot_bind name
    name = name.nick if name.is_a? BitServ::ServicesBot
    name = name.downcase
    
    profile = @config['binds'].find {|profile| profile['bot'].downcase == name }
    
    username = profile['username'] || profile['bot']
    bind bot_dn(username), profile['password']
  end
end
