module BitServ
  class GroupServ < ServicesBot
    command 'list', 'List all registered groups.'
    
    def cmd_list origin
      notice origin, "*** List of Registered Groups ***"
      notice origin, "Name            | (Members) Description"
      notice origin, "----------------+--------------------------"
      LDAP.search("ou=groups,ou=irc,#{LDAP.base}", {:objectclass => 'x-bit-ircGroup'}, :scope => Net::LDAP::SearchScope_SingleLevel).each do |group|
        notice origin, "#{group.ou.first.ljust 16}| (#{group.member.size}) #{group.description}"
      end
      notice origin, "*** End List ***"
    end
  end
end
