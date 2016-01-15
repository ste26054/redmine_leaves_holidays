module RedmineLeavesHolidays
  module Patches
    module  ProjectPatch
      def self.included(base) # :nodoc:
            #base.extend(ClassMethods)

            base.send(:include, ProjectInstanceMethods)

            base.class_eval do
              unloadable
              
              scope :system_leave_projects, lambda {
                ids = pluck(:id)
                system_leave_projects_ids = EnabledModule.where(name: "leave_management", project_id: ids).pluck(:project_id)
                enabled_management_rules_project_ids = LeavesHolidaysManagementsModules.leave_management_rules_enabled_projects.map(&:to_i)
                where(id: system_leave_projects_ids & enabled_management_rules_project_ids)
              }

            end             
        end
    end

    module ProjectInstanceMethods

      # Returns if leave management rules are enabled for the project
      def leave_management_rules_enabled?
        return self.id.in?(LeavesHolidaysManagementsModules.leave_management_rules_enabled_projects.map(&:to_i))
      end

      def is_system_leave_project?
        Project.where(id: self.id).active.system_leave_projects.any?
      end

      def role_list
        return self.users_by_role.keys.sort
      end

      def roles_for_user(user)
        return members.includes(:roles).where(user_id: user.id).map(&:roles).flatten.uniq
      end

      def users_for_roles(roles)
        unless roles.is_a?(Array)
          roles = [roles]
        end

        role_ids = roles.map(&:id)
        return members.includes(:user, :roles).where(roles: {id: role_ids}).map(&:user)
      end

      def user_list
        return self.users.sort
      end

      def users_roles_managed_by_leave_admin
        users_role = self.users_by_role
        users_role.each do |k,v|
          v.keep_if{ |user| user.is_managed_by_leave_admin?(self)}
        end
        users_role.delete_if{ |k,v| v.empty? }
        return users_role
      end

      def users_managed_by_leave_admin
        return self.users.to_a.keep_if{ |user| user.is_managed_by_leave_admin?(self) }
      end

      def contractors_by_role_notifying_plugin_admin
        contractors = self.contractor_list
        contractors_role = self.users_by_role
        contractors_role.each do |k,v|
          v.keep_if{ |user| (user.in?(contractors) && user.contractor_notifies_leave_admin?(self))}
        end
        contractors_role.delete_if{ |k,v| v.empty? }
        return contractors_role
      end

      def contractor_list
        return self.users.contractor.sort
      end

      def users_by_role_managed
        users_role = self.users_by_role
        users_role.each do |k,v|
          v.keep_if{ |user| LeavesHolidaysManagements.management_rules_list(user, 'sender', 'is_managed_by', project).any? }
        end
        users_role.delete_if{ |k,v| v.empty? }
        return users_role
      end

      def users_by_role_who_can_create_leave_requests
        users_role = self.users_by_role
        users_role.each do |k,v|
          v.keep_if{ |user| user.can_create_leave_requests}
        end
        users_role.delete_if{ |k,v| v.empty? }
        return users_role
      end

      def users_by_role_who_cant_create_leave_requests
        users_role = self.users_by_role
        users_role.each do |k,v|
          v.keep_if{ |user| !user.can_create_leave_requests}
        end
        users_role.delete_if{ |k,v| v.empty? }
        return users_role
      end

      def leave_administrators
        return LeaveAdministrator.where(project: self)
      end

      # Returns leave administrators for current project. If no leave administrator explicitly set, returns system leave administrators
      def get_leave_administrators
        obj = {users: [], project_defined: false}
        users = self.leave_administrators.includes(:user).map{|l| l.user}
        if users.any?
          obj[:users] = users
          obj[:project_defined] = true
        else
          obj[:users] = LeavesHolidaysLogic.plugin_admins_users
        end
        return obj
      end

    end
  end
end

unless Project.included_modules.include?(RedmineLeavesHolidays::Patches::ProjectPatch)
  Project.send(:include, RedmineLeavesHolidays::Patches::ProjectPatch)
end