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
      def role_list
        return self.users_by_role.keys.sort
      end

      def roles_for_user(user)
        return self.users_by_role.select{|k,v| user.in?(v)}.keys
      end

      def users_for_roles(roles)
        unless roles.is_a?(Array)
          roles = [roles]
        end

        return self.users_by_role.select{|role, users| role.in?(roles)}.values.flatten.uniq
      end

      def user_list
        return self.users.sort
      end

      def users_by_role_not_managed_anywhere
        users_role = self.users_by_role
        users_role.each do |k,v|
          v.keep_if{ |user| LeavesHolidaysManagements.management_rules_list(user, 'sender', 'is_managed_by').to_a.empty? && !user.id.in?(LeavesHolidaysLogic.plugin_admins)}
        end
        users_role.delete_if{ |k,v| v.empty? }
        return users_role
      end

    end
  end
end

unless Project.included_modules.include?(RedmineLeavesHolidays::Patches::ProjectPatch)
  Project.send(:include, RedmineLeavesHolidays::Patches::ProjectPatch)
end