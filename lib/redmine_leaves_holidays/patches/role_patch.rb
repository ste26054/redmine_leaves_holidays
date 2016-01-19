module RedmineLeavesHolidays
  module Patches
    module  RolePatch
      def self.included(base) # :nodoc:

        base.send(:include, RoleInstanceMethods)

            base.class_eval do
              unloadable # Send unloadable so it will not be unloaded in development
              
              has_many :leave_management_rules, as: :sender
              has_many :leave_management_rules, as: :receiver

              before_destroy :destroy_leave_management_rules

              def destroy_leave_management_rules
                as_sender = LeaveManagementRule.where(sender: self)
                as_receiver = LeaveManagementRule.where(receiver: self)
                as_sender.destroy_all
                as_receiver.destroy_all
              end

            end
        end
    end

    module RoleInstanceMethods
      include LeavesCommonUserRole
    end
  end
end

unless Role.included_modules.include?(RedmineLeavesHolidays::Patches::RolePatch)
  Role.send(:include, RedmineLeavesHolidays::Patches::RolePatch)
end