module BitServ
  class GroupServ < ServicesBot
    command 'list', 'List all registered groups.'
    command 'roles', 'Manage the roles for a certain group.', 1, 'group', 'action', true
    
    def cmd_list origin
      notice origin, "*** List of Registered Groups ***"
      Group.list.each do |group|
        notice origin, "#{group.name.ljust 16}| #{group.desc}"
      end
      notice origin, "*** End Group List ***"
    end
    
    def cmd_roles origin, group, action='list', *args
      LDAP.user_bind origin.nick, password
      
      case action
        when 'list'
          notice origin, "*** Group Roles List for #{group} ***"
          Group.load(group).roles.each do |role|
            notice origin, "#{role.name.ljust 16}| (#{role.members.size}) #{role.desc}"
          end
          notice origin, "*** End Role List ***"
        
      end
    end
  end
end
