module BitServ
class Account
  attr_accessor :entry
  
  def self.register username, password, attrs
    attrs[:userPassword] = `slappasswd -s #{password}`.chomp
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
  
  def initialize entry
    @entry = entry
  end
  
  def reload!
    @entry = LDAP.select @entry.dn, :attributes => ['*', 'memberof']
  end

  def cloak
    @entry.memberof.find{|x| x.count(',') > 4 } =~ /^ou=([^,]+),ou=([^,]+),/
    $1 && "#{@entry.uid}/#{$2}/#{$1}"
  end
end
end
