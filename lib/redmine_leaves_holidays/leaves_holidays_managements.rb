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

  def self.regroup(array)
    for i in 0..1
      array = array.group_by{|t| t[i]}.map{|k,v| [k, (v.flatten - k).uniq]}
      array.map(&:reverse!) if i.odd?
    end
    return array
  end

  def self.management_rules_list(actor, acting_as, action, projects = [], user_exceptions = [])
    if actor == nil || acting_as == nil || action == nil
      return []
    end
    return [] unless actor.class.to_s.in?(self.actor_types) || acting_as.in?(['sender', 'receiver']) || action.in?(LeaveManagementRule.actions)
    return [] if actor.class == Role && !projects && projects.empty?

    if projects && !projects.is_a?(Array)
      projects = [projects]
    end

    leave_management_rules_ids = []

    # Setting projects to lookup
    if actor.class == User
      # Set actual User class in db to Principal
      actor_type_db = 'Principal'
      # If no project list provided
      if projects.empty?
        # Get active actor projects where management rules are set
        project_list = actor.projects.where(id: LeaveManagementRule.projects.pluck(:id)).active.to_a
      else
        # get given project list
        project_list = projects
      end
      # Get associated memberhips of the User for given project list
      memberships = Member.where(user: actor, project: project_list)
      # and associated roles 
      member_roles = MemberRole.where(member_id: memberships).includes(member: :project).includes(:role)

      #get a hash [:project => [roles]] for the user
      roles_for_project =  member_roles.group_by{|mr| mr.member.project}.map{|k,v|  [k, v.map(&:role).uniq]}.to_h

      # Get management rules associated to the roles the user appears in for the given projects
      roles_for_project.each do |project, roles|
        leave_management_rules_ids << LeaveManagementRule.where(project: project, action: LeaveManagementRule.actions[action]).where("#{acting_as}_type".to_sym => 'Role', "#{acting_as}_id".to_sym => roles.map(&:id)).pluck(:id)
      end

      # Get management rules directly associated to the given user
      leave_management_rules_ids << LeaveManagementRule.where(project: roles_for_project.keys, action: LeaveManagementRule.actions[action]).where("#{acting_as}_type".to_sym => 'Principal', "#{acting_as}_id".to_sym => ([actor.id] - user_exceptions).flatten).pluck(:id)

    else
      actor_type_db = 'Role'
      project_list = projects

      project_list.each do |project|
        users = project.users_for_roles(actor)
        leave_management_rules_ids << LeaveManagementRule.where(project: project, action: LeaveManagementRule.actions[action]).where("#{acting_as}_type".to_sym => 'Principal',"#{acting_as}_id".to_sym => (users.map(&:id) - user_exceptions).flatten).pluck(:id)
      end
      # Get rules directly associated to the role
      leave_management_rules_ids << LeaveManagementRule.where(project: project_list, action: LeaveManagementRule.actions[action]).where("#{acting_as}_type".to_sym => actor_type_db, "#{acting_as}_id".to_sym => actor.id).pluck(:id)
    end

    exceptions = []
    if actor.class == User 
      exceptions = LeaveExceptionRule.where(actor_concerned: LeaveExceptionRule.actors_concerned[acting_as], user_id: actor.id).pluck(:leave_management_rule_id).uniq
    end

    leave_management_rules = LeaveManagementRule.where(id: leave_management_rules_ids.flatten.uniq - exceptions)

    return leave_management_rules
  end

  def self.management_rules_list_recursive(actor, acting_as, action, projects = [])
    leave_management_rules_initial = self.management_rules_list(actor, acting_as, action, projects)
    
    projects_ref = Project.where(id: leave_management_rules_initial.pluck(:project_id).uniq).to_a

    to_check = leave_management_rules_initial.to_a
    checked = []
    i = 1
    while !to_check.empty?
      to_check_next = []
      checked_loop = []
      (to_check.flatten - checked).each do |rule|
        actor = rule.send(self.acting_as_opposite(acting_as))
        exceptions = []
        unless rule.leave_exception_rules.empty?
          exceptions << rule.leave_exception_rules.where(actor_concerned: LeaveExceptionRule.actors_concerned[self.acting_as_opposite(acting_as)]).pluck(:user_id)
        end
        to_check_next << self.management_rules_list(actor, acting_as, action, projects_ref & [rule.project], exceptions.flatten)
        checked_loop << rule
      end
      checked << checked_loop unless checked_loop.empty?
      to_check = to_check_next
      i += 1

    end
    return checked
  end

  # Need to be called with rules bound to a single project !
  def self.group_management_rules(rule_ids)
    rules = LeaveManagementRule.where(id: rule_ids)
    rows = []
    # LeaveManagementRule.actions.keys.each do |action|
    #   LeavesHolidaysManagements.actor_types_db.each do |receiver_type| 
    #     LeavesHolidaysManagements.actor_types_db.each do |sender_type| 
          rules_grouped = LeavesHolidaysManagements.regroup(rules.to_a.map{|r| [[r.sender], [r.receiver]]}) 
          unless rules_grouped.empty? 

            rules_grouped.each do |v| 

              pregrouped_rules = rules.to_a.select {|r| r.sender.in?(v[0]) && r.receiver.in?(v[1])}.to_a

              exceptions_sender_rules = rules.joins(:leave_exception_rules).where(id: pregrouped_rules.map(&:id), leave_exception_rules: {actor_concerned: LeaveExceptionRule.actors_concerned['sender']}).to_a#.pluck(:id)

              exceptions_receiver_rules = rules.joins(:leave_exception_rules).where(id: pregrouped_rules.map(&:id), leave_exception_rules: {actor_concerned: LeaveExceptionRule.actors_concerned['receiver']}).to_a#.pluck(:id)

              no_excp = pregrouped_rules - exceptions_sender_rules - exceptions_receiver_rules
              both_excp = exceptions_sender_rules & exceptions_receiver_rules

              rows << no_excp unless no_excp.empty?
              rows << exceptions_sender_rules unless exceptions_sender_rules.empty?
              rows << exceptions_receiver_rules unless exceptions_receiver_rules.empty?
              rows << both_excp unless both_excp.empty?

        #     end
        #   end
        # end
      end
    end
    return rows.uniq
  end


end