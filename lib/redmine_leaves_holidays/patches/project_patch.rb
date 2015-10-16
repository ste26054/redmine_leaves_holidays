module RedmineLeavesHolidays
  module Patches
    module  ProjectPatch
      def self.included(base) # :nodoc:
            #base.extend(ClassMethods)

            base.send(:include, ProjectInstanceMethods)

            # base.class_eval do
            #   unloadable # Send unloadable so it will not be unloaded in development
              
            # end
        end
    end

    module ProjectInstanceMethods
      def roles_list
        return self.users_by_role.keys.sort
      end
    end
  end
end

unless Project.included_modules.include?(RedmineLeavesHolidays::Patches::ProjectPatch)
  Project.send(:include, RedmineLeavesHolidays::Patches::ProjectPatch)
end