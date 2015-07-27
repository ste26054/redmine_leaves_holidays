module RedmineLeavesHolidays
	module Patches
		module  UserPatch
			def self.included(base) # :nodoc:

				base.send(:include, UserInstanceMethods)

		        base.class_eval do
		          unloadable # Send unloadable so it will not be unloaded in development

		        end
		    end
		end

		module UserInstanceMethods
			def weekly_working_hours
				preference = LeavePreference.find_by(user_id: self.id)
				if preference == nil
					return RedmineLeavesHolidays::Setting.defaults_settings(:weekly_working_hours).to_f
				else
					return preference.weekly_working_hours
				end
			end
		end
	end
end

unless User.included_modules.include?(RedmineLeavesHolidays::Patches::UserPatch)
  User.send(:include, RedmineLeavesHolidays::Patches::UserPatch)
end