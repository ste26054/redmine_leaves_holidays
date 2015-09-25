module RedmineLeavesHolidays
	module Patches
		module  UserPatch
			def self.included(base) # :nodoc:

				base.send(:include, UserInstanceMethods)

		        base.class_eval do
		          unloadable # Send unloadable so it will not be unloaded in development
		          has_one :leave_preference
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

			def css_background_color
    		Digest::MD5.hexdigest(self.login)[0..5]
  		end

		  def css_style
		    hex = css_background_color
		    rgb = hex.match(/(..)(..)(..)/).to_a.drop(1).map(&:hex)

		    #http://www.w3.org/TR/AERT#color-contrast
		    treshold = ((rgb[0] * 299) + (rgb[1] * 587) + (rgb[2] * 114)) / 1000

		    font_color = treshold > 125 ? "black" : "white"

		    return "background: \##{hex}; color: #{font_color};"
		  end
		end
	end
end

unless User.included_modules.include?(RedmineLeavesHolidays::Patches::UserPatch)
  User.send(:include, RedmineLeavesHolidays::Patches::UserPatch)
end