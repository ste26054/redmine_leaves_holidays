module LeavesHolidaysManagementsModules

  def self.leave_management_rules_enabled_projects
    return LeaveManagedProject.pluck(:project_id)
  end

  def self.enable_leave_management_rules_project(project)
    lmp = LeaveManagedProject.where(project: project)
    LeaveManagedProject.create(project: project, user: User.current) if lmp.empty?
  end

  def self.disable_leave_management_rules_project(project)
    LeaveManagedProject.where(project: project).destroy_all
  end



end