module BitServ
  class GroupServ < ServicesBot
    command 'list', 'List all registered groups.'
    command 'create', 'Register your own group.', 'name', 'description', true
    command 'roles', 'Manage the roles for a certain group.', 1, 'group', 'action', true
    command 'member', 'Manage the members of a group.', 2, 'group', 'role', 'action', 'user'
    
    def cmd_list origin
      notice origin, "*** List of Registered Groups ***"
      Group.list.each do |group|
        notice origin, "#{group.name.ljust 16}| #{group.desc}"
      end
      notice origin, "*** End Group List ***"
    end
    
    def cmd_create origin, name, *desc
      LDAP.bot_bind self
      
      if Group.create name, origin, :description => desc.join(' ')
        notice origin, "The group ^B#{name}^B has been created. You have been placed in this group with the role 'contact'. Users in this role can manage the group. Feel free to create roles with ^B/msg #{@nick} roles #{name} add *role*^B."
      else
        notice origin, "An error occured while creating ^B#{name}^B: #{LDAP.ldap.get_operation_result.message}"
      end
    end

    def cmd_roles origin, group, action='list', *args
      LDAP.bot_bind self
      group = Group.load(group)
      
      if action != 'list' && !group.admin?(origin)
        notice origin, "You aren't a contact of this group."
        return
      end
      
      case action
        when 'list'
          notice origin, "*** Group Roles List for #{group} ***"
          group.roles.each do |role|
            notice origin, "#{role.name.ljust 16}| (#{role.members.size}) #{role.desc}"
          end
          notice origin, "*** End Role List ***"
        
        when 'add'
          role = args.shift
          if group.create_role role, :description => args.join(' ')
            notice origin, "Created ^B#{role}^B under ^B#{group.name}^B. You may now add members with ^B/msg #{@nick} member #{group.name} #{role} add *username*^B."
          else
            notice origin, "An error occured while creating ^B#{role}^B under ^B#{group.name}^B: #{LDAP.ldap.get_operation_result.message}"
          end
        
        when 'del'
          role = group.roles.find{|role2| role2.name == args.first }
          if !role
            notice origin, "^B#{args.first}^B is not a role under ^B#{group.name}^B."
          elsif role.delete!
            notice origin, "Deleted ^B#{role.name}^B from ^B#{group.name}^B."
          else
            notice origin, "An error occured while deleting ^B#{role}^B from ^B#{group.name}^B: #{LDAP.ldap.get_operation_result.message}"
          end
      end
    end
    
    def cmd_member origin, group, role, action='list', user=nil
      LDAP.bot_bind 'NickServ'
            
      group = Group.load(group)
      role = group.roles.find{|role2| role2.name == role }
      
      user = user && Account.load(user)
      LDAP.bot_bind self
      
      if action != 'list' && group.admin?(origin)
        notice origin, "You aren't a contact of this group."
        return
      end
      
      case action
        when 'list'
          notice origin, "*** Member List for #{group.name}/#{role.name} ***"
          role.members.each do |member|
            notice origin, "#{member}"
          end
          notice origin, "*** End Member List ***"
        
        when 'add'
          if role.add user.entry.dn.first
            notice origin, "Added ^B#{user.entry.uid}^B to ^B#{group.name}/#{role.name}^B."
          else
            notice origin, "An error occured while adding ^B#{user.entry.uid}^B undetor ^B#{group.name}/#{role.name}^B: #{LDAP.ldap.get_operation_result.message}"
          end
        
        when 'del'
          if role.remove user.entry.dn.first
            notice origin, "Removed ^B#{user.entry.uid}^B from ^B#{group.name}/#{role.name}^B."
          else
            notice origin, "An error occured while removing ^B#{user.entry.uid}^B from ^B#{group.name}/#{role.name}^B: #{LDAP.ldap.get_operation_result.message}"
          end
      end
    end
  end
end
