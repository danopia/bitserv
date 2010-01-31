require 'ldap'
require 'escape'

module BitServ
class Account
  attr_accessor :entry
  
  def self.register username, password, attrs
    attrs[:userPassword] = `slappasswd -s #{Escape.shell_command password}`.chomp # TODO
    attrs[:objectclass] = ['x-bit-ircUser', 'top']
    attrs[:cn] ||= username
    attrs[:uid] ||= username
    
    e = LDAP.create(LDAP.user_dn(username), attrs)
    p e # Does this return the entry?
    e && self.new(e)
  end
  
  def self.load account
    entry = LDAP.select LDAP.user_dn(account), :attributes => ['*', 'memberof']
    entry && self.new(entry)
  end
  
  def self.exists? account
    LDAP.exists? LDAP.user_dn(account)
  end
  
  def initialize entry
    @entry = entry
  end
  
  def reload!
    @entry = LDAP.select @entry.dn, :attributes => ['*', 'memberof']
  end

  def cloak
    groups.find{|x| x.count(',') > 4 } =~ /^ou=([^,]+),ou=([^,]+),/
    $1 && "#{$2}/#{$1}/#{@entry.uid}"
  end
  
  def groups
    (@entry['memberof'] || []).select{|x| x.count(',') > 4 }
  end
end
end
