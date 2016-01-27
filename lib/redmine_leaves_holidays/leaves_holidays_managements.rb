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

  # returns the list of management rules regarding the actor given. Projects are filtered based on inputs & system leave projects
  def self.management_rules_list(actor, acting_as, action, projects = [], user_exceptions = [], include_backups = true)
    if actor == nil || acting_as == nil || action == nil
      return []
    end
    return [] unless actor.class.to_s.in?(self.actor_types) || acting_as.in?(['sender', 'receiver']) || action.in?(LeaveManagementRule.actions)
    return [] if actor.class == Role && !projects && projects.empty?

    if projects && !projects.is_a?(Array)
      projects = [projects]
    end

    leave_management_rules_action = LeaveManagementRule.actions[action]
    leave_management_rules_ids = []
    exceptions = []

    # Setting projects to lookup
    if actor.class == User
      # Set actual User class in db to Principal
      actor_type_db = 'Principal'
      # If no project list provided
      if projects.empty?
        # Get active actor projects where management rules are set
        # project_list = actor.projects.where(id: LeaveManagementRule.projects.pluck(:id)).system_leave_projects.to_a
        # fetch projects between the actor projects and projects where lmr are set
        # project_list = actor.projects & LeaveManagementRule.projects
        project_list = actor.leave_projects & LeaveManagementRule.projects.to_a
      else
        # fetch projects between the given projects and projects where lmr are set
        # project_list = projects & Project.system_leave_projects.to_a
        project_list = projects & LeaveManagementRule.projects.to_a
      end

      # Get associated memberhips of the User for given project list
      memberships = Member.where(user: actor, project: project_list)
      # and associated roles 
      member_roles_ids = MemberRole.where(member_id: memberships).includes(member: :project)

      #get a hash [:project => [roles]] for the user
      role_ids_for_project_id = member_roles_ids.group_by{|mr| mr.member.project_id}.map{|k,v|  [k, v.map(&:role_id).uniq]}.to_h

      # After improvement
      leave_management_rules = LeaveManagementRule.where(project: project_list, action: leave_management_rules_action)
      lmr_project_ids = leave_management_rules.group_by(&:project_id)
      # Get management rules associated to the roles the user appears in for the given projects
      lmr_project_ids.each do |project_id, lmrs|
        selected = []
       selected = lmrs.select{|lm| lm.send("#{acting_as}_type") == 'Role' && role_ids_for_project_id[project_id] && lm.send("#{acting_as}_id").in?(role_ids_for_project_id[project_id])}.map(&:id) if role_ids_for_project_id.any?
       leave_management_rules_ids << selected if selected.any?
      end

      # Get management rules directly associated to the given user
      selected = lmr_project_ids.values.flatten.select{|lmrs| lmrs.send("#{acting_as}_type") == 'Principal' && lmrs.send("#{acting_as}_id").in?(([actor.id] - user_exceptions).flatten)}.map(&:id)
      leave_management_rules_ids << selected if selected.any?

      # Get management rules where the user acts as a backup
      if acting_as == 'receiver' && include_backups && action == "is_managed_by"
        leave_management_rules_ids << leave_management_rules.joins(:leave_exception_rules).where(leave_exception_rules: {user_id: actor.id, actor_concerned: LeaveExceptionRule.actors_concerned["backup_receiver"]}).pluck(:id)
      end

      # If we found rules where the user acts as a role, but there are exceptions on these rules excluding the user, then ignore the rules associated
      exceptions = LeaveExceptionRule.where(actor_concerned: LeaveExceptionRule.actors_concerned[acting_as], user_id: actor.id).pluck(:leave_management_rule_id).uniq

      return leave_management_rules.where(id: leave_management_rules_ids.flatten.uniq - exceptions)

    else
      # NEED TO IMPROVE THIS PART AS ABOVE
      actor_type_db = 'Role'
      project_list = projects

      project_list.each do |project|
        users = project.users_for_roles(actor)
        leave_management_rules_ids << LeaveManagementRule.where(project: project, action: leave_management_rules_action).where("#{acting_as}_type".to_sym => 'Principal',"#{acting_as}_id".to_sym => (users.map(&:id) - user_exceptions).flatten).pluck(:id)
      end
      # Get rules directly associated to the role
      leave_management_rules_ids << LeaveManagementRule.where(project: project_list, action: leave_management_rules_action).where("#{acting_as}_type".to_sym => actor_type_db, "#{acting_as}_id".to_sym => actor.id).pluck(:id)


      #After improvement

      #leave_management_rules = LeaveManagementRule.where(project: project_list, action: leave_management_rules_action)
      #lmr_project_ids = leave_management_rules.group_by(&:project_id)


    end

    leave_management_rules = LeaveManagementRule.where(id: leave_management_rules_ids.flatten.uniq - exceptions)

    return leave_management_rules
  end

  def self.management_rules_list_recursive(actor_initial, acting_as, action, projects = [])
    leave_management_rules_initial = self.management_rules_list(actor_initial, acting_as, action, projects)
    
    projects_ref = Project.where(id: leave_management_rules_initial.pluck(:project_id).uniq).to_a

    to_check = leave_management_rules_initial.to_a
    checked = []
    i = 1
    while !to_check.empty? && i < 5
      to_check_next = []
      checked_loop = []
      to_check.each do |rule|
        actor = rule.send(self.acting_as_opposite(acting_as))
        exceptions = []

        unless rule.leave_exception_rules.empty?
          exceptions << rule.leave_exception_rules.where(actor_concerned: LeaveExceptionRule.actors_concerned[self.acting_as_opposite(acting_as)]).pluck(:user_id)
        end

        unless acting_as == 'receiver' && action == 'is_managed_by' && actor_initial.class == User && actor_initial.id.in?(rule.leave_exception_rules.where(actor_concerned: LeaveExceptionRule.actors_concerned['backup_receiver'], user_id: actor_initial.id).pluck(:user_id)) && !actor_initial.in?(rule.to_users[:user_receivers])

          to_check_next << self.management_rules_list(actor, acting_as, action, projects_ref & [rule.project], exceptions.flatten)
        end
        
        checked_loop << rule
      end
      checked << checked_loop unless checked_loop.empty?
      to_check = to_check_next.flatten.uniq - checked.flatten.uniq
      i += 1

    end
    return checked
  end

  def self.management_rules_list_recursive_with_nesting(actor, acting_as, action, projects = [])
    management_rules = self.management_rules_list_recursive(actor, acting_as, action, projects)
    rules_nesting = []

    management_rules.each do |rules|
      rules.each_with_index do |rule, nesting_level|
        rules_nesting << {nesting: nesting_level, rule: rule}
      end
    end

    return rules_nesting.flatten.group_by{|r| r[:nesting]}
  end

  #in: [[1, 2], [3, 4], [5], [6, 7, 8], [9], [10, 11]]
  #out: [[1, 3, 5, 6, 9, 10], [2, 4, 7, 11], [8]]
  def self.slice_array_of_arrays(array_of_arrays)
    out = []
    for i in 0..(array_of_arrays.map(&:size).max - 1)
      out << array_of_arrays.map{|a| a.slice(i)}.compact
    end
    return out
  end

  def self.check_discrepancies_for(actor, acting_as, action, projects = [])
    principal_rules = self.management_rules_list(actor, acting_as, action, projects)
    descendent_rules = self.management_rules_list_recursive(actor, acting_as, action, projects).flatten.uniq - principal_rules

    return descendent_rules.flatten.select {|r| actor == r.send(self.acting_as_opposite(acting_as))}
  end

  def self.regroup(array)
    for i in 0..1
      array = array.group_by{|t| t[i]}.map{|k,v| [k, (v.flatten - k).uniq]}
      array.map(&:reverse!) if i.odd?
    end
    return array
  end

  def self.group_management_rules(rule_ids)
    rules = LeaveManagementRule.where(id: rule_ids).includes(:leave_exception_rules)
    rules_array = []

    rules.find_each do |rule|

      rule_object = {id: rule.id, project_id: rule.project_id, sender_id: rule.sender_id, sender_type: rule.sender_type, action: rule.action, receiver_id: rule.receiver_id, receiver_type: rule.receiver_type, exceptions_sender: [], exceptions_receiver: [], backup_receiver: []}

      rule.leave_exception_rules.includes(:user).find_each do |exception|
        excp = {user_id: exception.user_id}
        if exception.actor_concerned == 'sender'
          rule_object[:exceptions_sender] << excp
        end
        if exception.actor_concerned == 'receiver'
          rule_object[:exceptions_receiver] << excp
        end
        if exception.actor_concerned == 'backup_receiver'
          rule_object[:backup_receiver] << excp
        end
      end

      rules_array << rule_object
    end
    #return rules_array
    return rules_array.group_by{|r| [r[:project_id], r[:sender_type], r[:action], r[:receiver_type], r[:exceptions_sender], r[:exceptions_receiver], r[:backup_receiver]]}.values.map{|a| a.map{|b| b[:id]}}
  end

  def self.deep_group_management_rules(rules)
    rules_grouped_ids = self.group_management_rules(rules.map(&:id))

    snd_recv = []
    rules_grouped_ids.each do |rule_id_group|
      rule_group = rules.select{|r| r.id.in?(rule_id_group)}
      sender_receiver_groups = rule_group.group_by{|r| r.receiver}.inject({}) {|h, (k,v)| h[k] = v.map(&:sender); h}.group_by {|k,v| v}.inject({}) {|h, (k,v)| h[k] = v.map{|a| a.flatten - k.flatten}.flatten; h}.map {|sender, receiver| sender.product(receiver)}
      subgp = []
      sender_receiver_groups.each do |subgroup|
        subgp << subgroup.map{|sr| rule_group.select{|rule| sr[0] == rule.sender && sr[1] == rule.receiver }.first}.map(&:id)
      end
      snd_recv << subgp unless subgp.empty?
       
    end
    return snd_recv.flatten(1)
  end


end