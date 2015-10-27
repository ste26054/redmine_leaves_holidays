module LeavesHolidaysManagements

 def self.actor_types
  return ['Role', 'User']
 end

 def self.default_actor_type
  return self.actor_types[0]
 end



 # Returns the list of management rules for the given user (The user appears either as a Principal, or as a Role in the Rules)
 def self.user_action_actor_list(user, actor, action)
  return [] unless actor.in?(['sender', 'receiver']) || action.in?(LeaveManagementRule.actions.keys)

  # list of projects where user is a member and there are management rules defined
  leave_management_project_list = user.projects.where(id: LeaveManagementRule.projects.pluck(:id)).active
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
  leave_management_project_list.to_a.each do |project|
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
  
  return LeaveManagementRule.where(id: rules_list_ids - rules_exception_list_ids)
 end
end