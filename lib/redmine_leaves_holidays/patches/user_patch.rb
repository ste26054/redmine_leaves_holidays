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
			include LeavesHolidaysLogic

			def leave_preferences
				LeavePreference.find_by(user_id: self.id) || LeavesHolidaysLogic.retrieve_leave_preferences(self)
			end

			def weekly_working_hours
				return self.leave_preferences.weekly_working_hours
			end
			
			def leave_memberships
				return LeavesHolidaysLogic.leave_memberships(self)
			end

			def contract_period(current_date = Date.today)
				lp = self.leave_preferences
				return LeavesHolidaysDates.get_contract_period(lp.contract_start_date, lp.leave_renewal_date, current_date)
			end

			def days_remaining
				period = self.contract_period
				return LeavesHolidaysDates.total_leave_days_remaining(self, period[:start], period[:end])
			end

			def days_taken
				period = self.contract_period
				return LeavesHolidaysDates.total_leave_days_taken(self, period[:start], period[:end])
			end

			def days_accumulated
				period = self.contract_period
				return LeavesHolidaysDates.total_leave_days_accumulated(self, period[:start], Date.today)
			end
		end
	end
end

unless User.included_modules.include?(RedmineLeavesHolidays::Patches::UserPatch)
  User.send(:include, RedmineLeavesHolidays::Patches::UserPatch)
end