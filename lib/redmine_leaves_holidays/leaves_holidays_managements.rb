module LeavesHolidaysManagements

 def self.actor_types
  return ['Role', 'User']
 end

 def self.default_actor_type
  return self.actor_types[0]
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





end