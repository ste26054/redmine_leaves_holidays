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
    end
  end
end

unless Project.included_modules.include?(RedmineLeavesHolidays::Patches::ProjectPatch)
  Project.send(:include, RedmineLeavesHolidays::Patches::ProjectPatch)
end