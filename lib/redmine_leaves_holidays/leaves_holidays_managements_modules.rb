module LeavesHolidaysManagementsModules

  def self.leave_management_rules_enabled_projects
    return Setting.plugin_redmine_leaves_holidays['enabled_lvm_projects'] || []
  end

  def self.enable_leave_management_rules_project(project)
    s = Setting.find_by(name: 'plugin_redmine_leaves_holidays')
    v = s.value

    project_ids = self.leave_management_rules_enabled_projects

    project_ids << project.id.to_s
    v['enabled_lvm_projects'] = project_ids.uniq

    s.value = v

    s.save
    Setting.clear_cache
  end

  def self.disable_leave_management_rules_project(project)
    s = Setting.find_by(name: 'plugin_redmine_leaves_holidays')
    v = s.value

    project_ids = self.leave_management_rules_enabled_projects

    project_ids -= [project.id.to_s]
    v['enabled_lvm_projects'] = project_ids.uniq

    s.value = v

    s.save
    Setting.clear_cache
  end



end