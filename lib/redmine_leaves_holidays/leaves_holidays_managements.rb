module LeavesHolidaysManagements

 def self.actor_types
  return ['Role', 'User']
 end

 def self.actor_types_db
  return ['Role', 'Principal']
 end

 def self.default_actor_type
  return self.actor_types[0]
 end

 def self.acting_as_list
  return ['sender','receiver']
 end

 def self.acting_as_opposite(acting_as)
  return nil unless acting_as.in?(self.acting_as_list)
  return (self.acting_as_list - [acting_as]).first
 end



 # Returns the list of management rules for the given user (The user appears either as a User, or as a Role in the Rules)
  def self.user_action_actor_list(user, actor, action, leave_management_project_list = [])
    return [] unless actor.in?(['sender', 'receiver']) || action.in?(LeaveManagementRule.actions.keys)

    unless leave_management_project_list.is_a?(Array)
      leave_management_project_list = [leave_management_project_list]
    end

    # list of projects where user is a member and there are management rules defined
    if leave_management_project_list.empty?
      leave_management_project_list = user.projects.where(id: LeaveManagementRule.projects.pluck(:id)).active.to_a
    else
      leave_management_project_list = user.projects.where(id: leave_management_project_list.map(&:id)).active.to_a
    end
    # get associated rules
    leave_management_rules = LeaveManagementRule.where(project: leave_management_project_list, action: LeaveManagementRule.actions[action])
    rules_list = []

    if actor == 'sender'
      rules_list << leave_management_rules.sender_user.where(sender: user).pluck(:id)
      rules_role = leave_management_rules.sender_role
    else
      rules_list << leave_management_rules.receiver_user.where(receiver: user).pluck(:id)
      rules_role = leave_management_rules.receiver_role
    end

     # For each project
    leave_management_project_list.each do |project|
      # get associated roles for given user
      if actor == 'sender'
        rules_list << rules_role.where(sender: project.roles_for_user(user), project: project).pluck(:id)
      else
        rules_list << rules_role.where(receiver: project.roles_for_user(user), project: project).pluck(:id)
      end
    end

    rules_list_ids = rules_list.flatten

    #get rules where there is an exception regarding the given user
    rules_exception_list_ids = LeaveExceptionRule.where(leave_management_rule_id: rules_list_ids, actor_concerned: LeaveExceptionRule.actors_concerned[actor], user: user).pluck(:leave_management_rule_id).uniq

    return LeaveManagementRule.where(id: rules_list_ids - rules_exception_list_ids)#.includes(:sender, :receiver, :project)
  end


  def self.role_action_actor_list(role, actor, action, leave_management_project_list)
    return [] unless actor.in?(['sender', 'receiver']) || action.in?(LeaveManagementRule.actions.keys)

    unless leave_management_project_list.is_a?(Array)
      leave_management_project_list = [leave_management_project_list]
    end

    # get associated rules
    leave_management_rules = LeaveManagementRule.where(project: leave_management_project_list, action: LeaveManagementRule.actions[action])
    rules_list = []

    if actor == 'sender'
      rules_list << leave_management_rules.sender_role.where(sender: role).pluck(:id)
    else
      rules_list << leave_management_rules.receiver_role.where(receiver: role).pluck(:id)
    end

    rules_list_ids = rules_list.flatten

    #get rules where there is an exception regarding the given user
    #rules_exception_list_ids = LeaveExceptionRule.where(leave_management_rule_id: rules_list_ids, actor_concerned: LeaveExceptionRule.actors_concerned[actor], user: user).pluck(:leave_management_rule_id).uniq

    return LeaveManagementRule.where(id: rules_list_ids)# - rules_exception_list_ids)#.includes(:sender, :receiver, :project)
  end

  def self.leave_manages_user_recursive(to_check = [], checked = [], project_list = [], freeze_project_list = false, force_users = true)
      unless to_check.is_a?(Array)
          to_check = [to_check]
      end

      if (freeze_project_list == false && checked.empty?) || !(freeze_project_list == true && !project_list.empty?)
        project_list = to_check.map{|u| u.leave_manages.map(&:project)}.flatten.uniq
      end
      to_be_checked_next = []
      (to_check - checked).each do |m|
        to_be_checked_next << m.leave_manages(force_users, project_list)
        checked << m
      end

      unless to_be_checked_next.empty?
        self.leave_manages_user_recursive(to_be_checked_next.flatten, checked, project_list, freeze_project_list, force_users)
      else
        return checked
      end

  end

  def self.leave_manages_role_recursive(to_check = [], checked = [], project_list = [])
      unless to_check.is_a?(Array)
          to_check = [to_check]
      end

      to_be_checked_next = []
      (to_check - checked).each do |m|
        to_be_checked_next << m.leave_manages(project_list).map(&:sender).select{|r| r.sender.class = Role}
        checked << m
      end

      unless to_be_checked_next.empty?
        self.leave_manages_role_recursive(to_be_checked_next.flatten, checked, project_list)
      else
        return checked
      end

  end

  #TBC
  def self.regroup(array)
    for i in 0..1
      array = array.group_by{|t| t[i]}.map{|k,v| [k, (v.flatten - k).uniq]}
      array.map(&:reverse!) if i.odd?
    end
    return array
  end

  def self.management_rules_list(actor, acting_as, action, projects = [])
    if actor == nil || acting_as == nil || action == nil
      return []
    end
    return [] unless actor.class.to_s.in?(self.actor_types) || acting_as.in?(['sender', 'receiver']) || action.in?(LeaveManagementRule.actions)
    return [] if actor.class == Role && !projects && projects.empty?

    # Setting projects to lookup
    if actor.class == User
      actor_type_db = 'Principal'
      if projects.empty?
        project_list = actor.projects.where(id: LeaveManagementRule.projects.pluck(:id)).active.to_a
      else
        project_list = projects
      end
      memberships = Member.where(user: actor, project: project_list)
      member_roles = MemberRole.where(member_id: memberships).includes(member: :project).includes(:role)

      #get a hash [:project => [roles]] for the user
      roles_for_project =  member_roles.group_by{|mr| mr.member.project}.map{|k,v|  [k, v.map(&:role).uniq]}.to_h

      leave_management_rules_ids = []
      roles_for_project.each do |project, roles|
        leave_management_rules_ids << LeaveManagementRule.where(project: project, action: LeaveManagementRule.actions[action]).where("#{acting_as}_type = 'Role' AND #{acting_as}_id = ?", roles.map(&:id)).pluck(:id)
      end

      leave_management_rules_ids << LeaveManagementRule.where(project: roles_for_project.keys, action: LeaveManagementRule.actions[action]).where("#{acting_as}_type = 'Principal' AND #{acting_as}_id = ?", actor.id).pluck(:id)

    else
      actor_type_db = 'Role'
      project_list = projects

      leave_management_rules_ids = LeaveManagementRule.where(project: project_list, action: LeaveManagementRule.actions[action]).where("#{acting_as}_type = ? AND #{acting_as}_id = ?", actor_type_db, actor.id).pluck(:id)
    end

    exceptions = []
    if actor.class == User 
      exceptions = LeaveExceptionRule.where(actor_concerned: LeaveExceptionRule.actors_concerned[acting_as], user: actor).pluck(:leave_management_rule_id).uniq
    end

    leave_management_rules = LeaveManagementRule.where(id: leave_management_rules_ids.flatten.uniq - exceptions).includes(:sender, :receiver, :leave_exception_rules, :project)

    return leave_management_rules.map(&:id)
  end





end