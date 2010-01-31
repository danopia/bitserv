require 'ldap'

module BitServ
class Group
  attr_accessor :entry, :roles
  
  def self.group_dn group
    "ou=#{group},ou=groups,ou=irc,#{LDAP.base}"
  end
  
  def self.list
    LDAP.search("ou=groups,ou=irc,#{LDAP.base}", {:objectclass => 'x-bit-ircGroup'}, :scope => Net::LDAP::SearchScope_SingleLevel).map{|entry| Group.new([entry]) }
  end
  
  def self.create name, user, attrs={}
    attrs[:objectclass] = ['x-bit-ircGroup', 'top']
    attrs[:ou] ||= name
    
    LDAP.create(group_dn(name), attrs)
    
    unless LDAP.success?
      puts "Result: #{LDAP.ldap.get_operation_result.code}"
      puts "Message: #{LDAP.ldap.get_operation_result.message}"
      return false
    end
    
    attrs = {
      :objectclass => ['x-bit-ircGroup', 'top'],
      :ou => 'contact',
      :member => user.dn,
      :description => 'Users that can manage the group'
    }
    
    LDAP.create("ou=contact,#{group_dn name}", attrs)
    
    unless LDAP.success?
      puts "Result: #{LDAP.ldap.get_operation_result.code}"
      puts "Message: #{LDAP.ldap.get_operation_result.message}"
    end
    LDAP.success?
  end
  
  def self.load group
    entries = LDAP.search(group_dn(group), {:objectclass => 'x-bit-ircGroup'})
    entries.any? && self.new(entries)
  end
  
  def self.exists? group
    LDAP.exists? group_dn(group)
  end
  
  def initialize entries
    @entry = entries.shift
    @roles = entries.map{|entry| Role.new(entry) }
  end
  
  def reload!
    entries = LDAP.search(@entry.dn, {:objectclass => 'x-bit-ircGroup'})
    @entry = entries.shift
    @roles = entries.map{|entry| Role.new(entry) }
  end
  
  def members
    @roles.inject([]) {|list, role| list + role.members}
  end
  
  def name
    @entry['ou'].first
  end
  def desc
    @entry['description'].first
  end
  
  def create_role name, attrs={}
    attrs[:objectclass] = ['x-bit-ircGroup', 'top']
    attrs[:ou] ||= name
    attrs[:member] ||= [LDAP.user_dn('ldap_empty_group')]
    
    LDAP.create("ou=#{name},#{@entry.dn}", attrs)
    
    unless LDAP.success?
      puts "Result: #{LDAP.ldap.get_operation_result.code}"
      puts "Message: #{LDAP.ldap.get_operation_result.message}"
    end
    LDAP.success?
  end
  
  def [] name
    @roles.find{|role| role.name == name }
  end
  
  def admin? user
    return false unless user.account
    self['contact'] && self['contact'].members.include?(user.dn)
  end
end

class Role
  attr_accessor :entry
  
  def self.role_dn group, role
    "ou=#{role},#{Group.group_dn group}"
  end
  
  def self.load group, role
    entry = LDAP.select role_dn(group, role)
    entry && self.new(entry)
  end
  
  def self.exists? group, role
    LDAP.exists? role_dn(group, role)
  end
  
  def initialize entry
    @entry = entry
  end
  
  def reload!
    @entry = LDAP.select @entry.dn
  end
  
  def delete!
    LDAP.delete @entry.dn.first
  end
  
  def add member
    LDAP.ldap.modify :dn => @entry.dn.first, :operations => [[:add, :member, member]]
    LDAP.success?
  end
  def remove member
    LDAP.ldap.modify :dn => @entry.dn.first, :operations => [[:delete, :member, member]]
    LDAP.success?
  end
  
  def members
    @entry['member'] || []
  end
  
  def name
    @entry['ou'].first
  end
  def desc
    @entry['description'].first
  end
end
end
