module RedmineLeavesHolidays
  module Patches
    module  ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

            base.class_eval do
              unloadable

              alias_method_chain :project_settings_tabs, :leave_management
            end
      end

      module InstanceMethods
            def project_settings_tabs_with_leave_management
              tabs = project_settings_tabs_without_leave_management

              tabs.push({ :name => 'leave_management',
                          :action => :view_leave_management,
                          :partial => 'projects/leave_management_settings',
                          :label => :tab_leaves_approval}) if @project.module_enabled?(:leave_management)

              tabs
            end
        end
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineLeavesHolidays::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineLeavesHolidays::Patches::ProjectsHelperPatch)
end