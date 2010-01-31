module BitServ
  class GroupServ < ServicesBot
    command 'list', 'List all registered groups.'
    command 'roles', 'Manage the roles for a certain group.', 'group'
    
    def cmd_list origin
      notice origin, "*** List of Registered Groups ***"
      notice origin, "Name            | (Members) Description"
      notice origin, "----------------+--------------------------"
      LDAP.search("ou=groups,ou=irc,#{LDAP.base}", {:objectclass => 'x-bit-ircGroup'}, :scope => Net::LDAP::SearchScope_SingleLevel).each do |group|
        notice origin, "#{group.ou.first.ljust 16}| (#{group.member.size}) #{group.description}"
      end
      notice origin, "*** End Group List ***"
    end
    
    def cmd_roles origin, group
      notice origin, "*** Group Roles List for #{group}***"
      notice origin, "Role            | (Members) Description"
      notice origin, "----------------+--------------------------"
      LDAP.search("ou=#{group},ou=groups,ou=irc,#{LDAP.base}", {:objectclass => 'x-bit-ircGroup'}, :scope => Net::LDAP::SearchScope_SingleLevel).each do |role|
        notice origin, "#{role.ou.first.ljust 16}| (#{role.member.size}) #{role.description}"
      end
      notice origin, "*** End Role List ***"
    end
  end
end
