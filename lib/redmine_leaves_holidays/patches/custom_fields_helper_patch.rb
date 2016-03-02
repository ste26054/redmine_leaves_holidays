module RedmineLeavesHolidays
  module Patches
    module  CustomFieldsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

            base.class_eval do
              unloadable
              
            end
      end

      module InstanceMethods
              CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => 'LeaveRequestCustomField', :partial => 'custom_fields/index', :label => :leave_short}
      end
    end
  end
end

unless CustomFieldsHelper.included_modules.include?(RedmineLeavesHolidays::Patches::CustomFieldsHelperPatch)
  CustomFieldsHelper.send(:include, RedmineLeavesHolidays::Patches::CustomFieldsHelperPatch)
end