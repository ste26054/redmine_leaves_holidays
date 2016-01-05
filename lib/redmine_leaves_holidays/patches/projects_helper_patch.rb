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
                          :label => :tab_leaves_approval}) if @project.module_enabled?(:leave_management) && User.current.allowed_to?(:manage_leave_management_rules, @project)

              tabs
            end

            def users_link_to_notification(users)
              users.map{|user| link_to user.name, notification_user_leave_preference_path(user)}.join(', ').html_safe
            end

            def project_link_to_manage_leave_administrators
              administrators_set = @project.leave_administrators.any?

              if administrators_set
                link_to "Edit leave administrators", project_leave_administrators_edit_path(@project.id), :remote => true, :class => "icon icon-edit"
              else
                link_to "Set leave administrators", project_leave_administrators_edit_path(@project.id), :remote => true, :class => "icon icon-add"
              end
            end
        end
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineLeavesHolidays::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineLeavesHolidays::Patches::ProjectsHelperPatch)
end