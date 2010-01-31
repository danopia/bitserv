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
      LDAP.bot_bind self
      
      case action
        when 'list'
          notice origin, "*** Group Roles List for #{group} ***"
          Group.load(group).roles.each do |role|
            notice origin, "#{role.name.ljust 16}| (#{role.members.size}) #{role.desc}"
          end
          notice origin, "*** End Role List ***"
        
        when 'add'
          group = Group.load(group)
          role = args.shift
          if group.create_role role, :description => args.join(' ')
            notice origin, "Created ^B#{role}^B under ^B#{group.name}^B. You may now add members."
          else
            notice origin, "An error occured while creating ^B#{role}^B under ^B#{group.name}^B: #{LDAP.ldap.get_operation_result.message}"
          end
      end
    end
  end
end
