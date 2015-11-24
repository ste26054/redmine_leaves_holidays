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
      def manage_rules_project(project)
        return LeavesHolidaysManagements.management_rules_list_recursive(self, 'receiver', 'is_managed_by', project)
      end

      def managed_rules_project(project)
        return LeavesHolidaysManagements.management_rules_list_recursive(self, 'sender', 'is_managed_by', project)
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

      def managed_users_project(project)
        managed_rules = self.managed_rules_project(project)
        managed_users = {directly: [], indirectly: []}


        managed_rules.each_with_index do |rules, nesting| 
          users = rules.map(&:to_users).map{|r| r[:user_senders]}.flatten.uniq 
          if nesting == 0 
            managed_users[:directly] << users
          else
            managed_users[:indirectly] << users
          end 
        end

        return managed_users
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
  end
end

unless Role.included_modules.include?(RedmineLeavesHolidays::Patches::RolePatch)
  Role.send(:include, RedmineLeavesHolidays::Patches::RolePatch)
end