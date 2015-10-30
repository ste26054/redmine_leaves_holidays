module RedmineLeavesHolidays
  module Patches
    module  RolePatch
      def self.included(base) # :nodoc:

        base.send(:include, RoleInstanceMethods)

            base.class_eval do
              unloadable # Send unloadable so it will not be unloaded in development
              has_many :leave_management_rules, as: :sender, dependent: :destroy
              has_many :leave_management_rules, as: :receiver, dependent: :destroy

            end
        end
    end

    module RoleInstanceMethods
      def leave_manages(project_list)
        management_rules = LeavesHolidaysManagements.role_action_actor_list(self, 'receiver', 'is_managed_by', project_list)
        return management_rules
      end

      def leave_roles_manage_list(project_list)
        return LeavesHolidaysManagements.leave_manages_role_recursive(self, [], project_list) - [self]
      end

    end
  end
end

unless Role.included_modules.include?(RedmineLeavesHolidays::Patches::RolePatch)
  Role.send(:include, RedmineLeavesHolidays::Patches::RolePatch)
end