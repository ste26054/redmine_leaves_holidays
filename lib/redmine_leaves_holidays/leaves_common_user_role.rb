module LeavesCommonUserRole
# All results are returned according to the rules set, and does not vary depending on if a manager is on leave when the method is called.
  def manage_rules_project(project)
    return LeavesHolidaysManagements.management_rules_list_recursive(self, 'receiver', 'is_managed_by', project)
  end

  def managed_rules_project(project)
    return LeavesHolidaysManagements.management_rules_list_recursive(self, 'sender', 'is_managed_by', project)
  end

  def managed_rules
    return LeavesHolidaysManagements.management_rules_list_recursive(self, 'sender', 'is_managed_by')
  end

  def manage_rules
    return LeavesHolidaysManagements.management_rules_list_recursive(self, 'receiver', 'is_managed_by')
  end

  def consulted_rules
    return LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'consults')
  end

  def consult_rules
    return LeavesHolidaysManagements.management_rules_list(self, 'sender', 'consults')
  end

  def notified_rules
    return LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'notifies_approved')
  end

  def notify_rules
    return LeavesHolidaysManagements.management_rules_list(self, 'sender', 'notifies_approved')
  end

  def manage_users_project(project)
    manage_rules = self.manage_rules_project(project)
    manage_users = {directly: [], indirectly: []}


    manage_rules.each_with_index do |rules, nesting| 
      users = rules.map(&:to_users).map{|r| r[:user_senders]}.flatten.uniq 
      if nesting == 0 
        manage_users[:directly] << users
      else
        manage_users[:indirectly] << users
      end 
    end

    return manage_users
  end

  def manage_users_project_with_backup(project)
    manage_rules = self.manage_rules_project(project)
    managed_users = {directly: [], indirectly: []}


    manage_rules.each_with_index do |rules, nesting| 
      rules_users_objects_by_backups = rules.map(&:to_users).group_by{|r| r[:backup_list]}.values

      rules_users_objects_by_backups.each do |rules_backup|
        backups = rules_backup.map{|r| r[:backup_list]}.flatten.uniq
        managed = rules_backup.map{|r| r[:user_senders]}.flatten.uniq
        managers = rules_backup.map{|r| r[:user_receivers]}.flatten.uniq
        if nesting == 0
          managed_users[:directly] << {managed: managed, managers: managers, backups: backups}
        else
          managed_users[:indirectly] << {managed: managed, managers: managers, backups: backups}
        end
      end
    end

    return managed_users
  end

  def manage_users_with_backup
    manage_rules = self.manage_rules
    managed_users = {directly: [], indirectly: []}


    manage_rules.each_with_index do |rules, nesting| 
      rules_users_objects_by_backups = rules.map(&:to_users).group_by{|r| r[:backup_list]}.values

      rules_users_objects_by_backups.each do |rules_backup|
        backups = rules_backup.map{|r| r[:backup_list]}.flatten.uniq
        managed = rules_backup.map{|r| r[:user_senders]}.flatten.uniq
        managers = rules_backup.map{|r| r[:user_receivers]}.flatten.uniq
        if nesting == 0
          managed_users[:directly] << {managed: managed, managers: managers, backups: backups}
        else
          managed_users[:indirectly] << {managed: managed, managers: managers, backups: backups}
        end
      end
    end

    return managed_users
  end

  def managed_users_project(project)
    managed_rules = self.managed_rules_project(project)
    managed_users = {directly: [], indirectly: []}


    managed_rules.each_with_index do |rules, nesting| 
    rules_users_objects = rules.map(&:to_users)
      users = rules_users_objects.map{|r| r[:user_receivers]}.flatten.uniq
      if nesting == 0
        managed_users[:directly] << users
      else
        managed_users[:indirectly] << users
      end
    end

    return managed_users
  end

  def managed_users_project_with_backup(project)
    managed_rules = self.managed_rules_project(project)
    managed_users = {directly: [], indirectly: []}


    managed_rules.each_with_index do |rules, nesting| 
      rules_users_objects_by_backups = rules.map(&:to_users).group_by{|r| r[:backup_list]}.values

      rules_users_objects_by_backups.each do |rules_backup|
        backups = rules_backup.map{|r| r[:backup_list]}.flatten.uniq
        managers = rules_backup.map{|r| r[:user_receivers]}.flatten.uniq
        if nesting == 0
          managed_users[:directly] << {managers: managers, backups: backups}
        else
          managed_users[:indirectly] << {managers: managers, backups: backups}
        end
      end
    end

    return managed_users
  end

  def managed_users_with_backup
    managed_rules = self.managed_rules
    managing_users = {directly: [], indirectly: []}


    managed_rules.each_with_index do |rules, nesting| 
      rules_users_objects_by_backups = rules.map(&:to_users).group_by{|r| r[:backup_list]}.values

      rules_users_objects_by_backups.each do |rules_backup|
        backups = rules_backup.map{|r| r[:backup_list]}.flatten.uniq
        managed = rules_backup.map{|r| r[:user_senders]}.flatten.uniq
        managers = rules_backup.map{|r| r[:user_receivers]}.flatten.uniq
        if nesting == 0
          managing_users[:directly] << {managed: managed, managers: managers, backups: backups}
        else
          managing_users[:indirectly] << {managed: managed, managers: managers, backups: backups}
        end
      end
    end

    return managing_users
  end

  # returns a list of project where the user is managed.
  # for each project, returns arrays of objects, each object containing a user and a is_on_leave boolean (if the user is on leave at the date given.
  # each array indicates a nesting level, the first array containing people that manages directly the object given
  def managed_users_with_backup_leave(date = Date.today)
    rule_users = self.managed_rules.flatten.map(&:to_users)

    users_on_leave = LeaveRequest.are_on_leave(rule_users.map{|o| [o[:user_senders].map(&:id), o[:user_receivers].map(&:id), o[:backup_list].map(&:id)]}.flatten.uniq, date)

    rule_users_per_project= rule_users.group_by{|r| r[:rule].project}
    
    managed_users = {}
    rule_users_per_project.each do |project, rules|
      managed_users[project] ||= []

      rules.each do |rule|
        managed_users[project] << rule[:user_receivers].map{|u| {user: u, is_on_leave: u.id.in?(users_on_leave), is_backup: false}}
        managed_users[project] << rule[:backup_list].map{|u| {user: u, is_on_leave: u.id.in?(users_on_leave), is_backup: true}} if rule[:backup_list].any?
      end
      
    end

    return managed_users
  end

  # Returns a list of project: users. each group of user is being backed up when on leave by the given user.
  def manage_users_with_backup_leave(date = Date.today)
    rule_users = self.manage_rules.flatten.map(&:to_users)

    users_on_leave = LeaveRequest.are_on_leave(rule_users.map{|o| [o[:user_senders].map(&:id), o[:user_receivers].map(&:id), o[:backup_list].map(&:id)]}.flatten.uniq, date)

    rule_users_per_project= rule_users.group_by{|r| r[:rule].project}
    
    manage_users = {}
    rule_users_per_project.each do |project, rules|
      manage_users[project] ||= []

      rules.each do |rule|
        manage_users[project] << rule[:user_receivers].map{|u| {user: u, is_on_leave: u.id.in?(users_on_leave)}}
      end

      manage_users[project] = manage_users[project].inject(&:&)
      
    end

    return manage_users
  end


  def consults_rules_project(project)
    return LeavesHolidaysManagements.management_rules_list(self, 'sender', 'consults', project)
  end

  def consulted_rules_project(project)
    return LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'consults', project)
  end

  def consults_users_project(project)
    consults_rules = self.consults_rules_project(project)
    return consults_rules.map(&:to_users).map{|r| r[:user_receivers]}.flatten.uniq
  end

  def consulted_users_project(project)
    consulted_rules = self.consulted_rules_project(project)
    return consulted_rules.map(&:to_users).map{|r| r[:user_senders]}.flatten.uniq
  end


  def notify_rules_project(project)
    return LeavesHolidaysManagements.management_rules_list(self, 'sender', 'notifies_approved', project)
  end

  def notified_rules_project(project)
    return LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'notifies_approved', project)
  end

  def notify_users_project(project)
    notify_rules = self.notify_rules_project(project)
    return notify_rules.map(&:to_users).map{|r| r[:user_receivers]}.flatten.uniq
  end

  def notified_users_project(project)
    notified_rules = self.notified_rules_project(project)
    return notified_rules.map(&:to_users).map{|r| r[:user_senders]}.flatten.uniq
  end
end