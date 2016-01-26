module RedmineLeavesHolidays
  module Patches
    module  IssuePatch
      def self.included(base)

        base.send(:include, IssueInstanceMethods)

            base.class_eval do
              unloadable # Send unloadable so it will not be unloaded in development
              
              has_many :leave_requests, dependent: :destroy
              has_many :leave_reason_rules, dependent: :destroy
            end
        end
    end

    module IssueInstanceMethods
      
    end
  end
end

unless Issue.included_modules.include?(RedmineLeavesHolidays::Patches::IssuePatch)
  Issue.send(:include, RedmineLeavesHolidays::Patches::IssuePatch)
end