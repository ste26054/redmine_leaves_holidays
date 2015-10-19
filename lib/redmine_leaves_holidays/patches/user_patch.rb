module RedmineLeavesHolidays
	module Patches
		module  UserPatch
			def self.included(base) # :nodoc:

				base.send(:include, UserInstanceMethods)

		        base.class_eval do
		          unloadable # Send unloadable so it will not be unloaded in development
		          has_one :leave_preference
		          has_many :leave_management_rules, as: :sender, dependent: :destroy
		          has_many :leave_management_rules, as: :receiver, dependent: :destroy

		          scope :with_leave_region, lambda { |arg|
		          	return nil if arg.blank?
						    arg = [*arg] or Array(arg)
						    args = arg.to_a & LeavesHolidaysLogic.get_region_list
						    ids = []
		          	uids_total = pluck(:id)
		          	users_with_lp = joins(:leave_preference).where(id: uids_total)
		          	uids_with_lp = users_with_lp.pluck(:id)
		          	uids_without_lp = uids_total - uids_with_lp

		          	ids << users_with_lp.joins(:leave_preference).where(:leave_preferences => {:region => args}).pluck(:id)

		          	ids << uids_without_lp if RedmineLeavesHolidays::Setting.defaults_settings(:region).in?(args)
		          	ids = ids.flatten.uniq

						    where(id: ids)
		          }

		          scope :not_contractor, lambda {
		          	ids = []
		          	uids_total = pluck(:id)
		          	users_with_lp = joins(:leave_preference).where(id: uids_total)
		          	uids_with_lp = users_with_lp.pluck(:id)
		          	uids_without_lp = uids_total - uids_with_lp

		          	ids << users_with_lp.joins(:leave_preference).where(:leave_preferences => {:is_contractor => 0}).pluck(:id)
		          	ids << uids_without_lp
		          	ids = ids.flatten.uniq

						    where(id: ids)
		          }
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

			def leave_period(current_date = Date.today)
				lp = self.leave_preferences
				return LeavesHolidaysDates.get_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date)
			end

			def previous_leave_period(current_date = Date.today)
				lp = self.leave_preferences
				return LeavesHolidaysDates.get_previous_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date)
			end

			def leave_period_to_date(current_date = Date.today)
				lp = self.leave_preferences
				period = LeavesHolidaysDates.get_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date)
				res = {}
				res[:start] = period[:start]
				res[:end] = current_date
				return res
			end

			def actual_days_max(current_date = Date.today)
				period = self.leave_period(current_date)
				return LeavesHolidaysDates.actual_days_max(self, period[:start], period[:end])
			end

			def days_remaining(current_date = Date.today)
				period = self.leave_period(current_date)
				return LeavesHolidaysDates.total_leave_days_remaining(self, period[:start], period[:end])
			end

			def days_taken_accepted(current_date = Date.today)
				period = self.leave_period(current_date)
				return LeavesHolidaysDates.total_leave_days_taken(self, period[:start], period[:end])
			end

			def days_taken_total(current_date = Date.today)
				period = self.leave_period(current_date)
				return LeavesHolidaysDates.total_leave_days_taken(self, period[:start], period[:end], true)
			end

			def days_accumulated(current_date = Date.today)
				period = self.leave_period(current_date)
				return LeavesHolidaysDates.total_leave_days_accumulated(self, period[:start], current_date)
			end

			def days_extra
				LeavesHolidaysLogic.user_params(self, :extra_leave_days).to_f
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

		  def working_days_count(from_date, to_date, include_sat = false, include_sun = false, include_bank_holidays = false)
				user_region = LeavesHolidaysLogic.user_params(self, :region)
				dates_interval = (from_date..to_date).to_a
				
				return dates_interval.count if include_sat && include_sun && include_bank_holidays

    			dates_interval.delete_if {|i| i.wday == 6 && !include_sat || #delete date from array if day of week is a saturday (6)
                			              i.wday == 0 && !include_sun || #delete date from array if day of week is a sunday (0)
                            		      !include_bank_holidays && i.holiday?(user_region.to_sym, :observed)
    									 }

    			return dates_interval.count

			end

			def is_contractor
				self.leave_preferences.is_contractor
			end
		end
	end
end

unless User.included_modules.include?(RedmineLeavesHolidays::Patches::UserPatch)
  User.send(:include, RedmineLeavesHolidays::Patches::UserPatch)
end