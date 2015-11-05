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

    end
  end
end

unless Role.included_modules.include?(RedmineLeavesHolidays::Patches::RolePatch)
  Role.send(:include, RedmineLeavesHolidays::Patches::RolePatch)
end