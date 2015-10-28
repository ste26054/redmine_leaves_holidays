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

		          # Returns all users in current scope that does not have a contract end date, or where contract end date > Today
		          scope :under_contract, lambda {
		          	ids = []
		          	uids_total = pluck(:id)
		          	uids_contracts_ended = joins(:leave_preference).where('leave_preferences.contract_end_date < ?', Date.today).pluck(:id)

		          	ids = uids_total - uids_contracts_ended
		          	
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
				return LeavesHolidaysDates.get_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date, false, lp.contract_end_date)
			end
			
			def previous_leave_period(current_date = Date.today)
				lp = self.leave_preferences
				return LeavesHolidaysDates.get_previous_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date, false, lp.contract_end_date)
			end

			def previous_leave_period(current_date = Date.today)
				lp = self.leave_preferences
				return LeavesHolidaysDates.get_previous_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date)
			end

			def leave_period_to_date(current_date = Date.today)
				lp = self.leave_preferences
				period = self.leave_period(current_date)
				if current_date >= period[:start] && current_date <= period[:end]
					period[:end] = current_date
					return period
				end
				if current_date < period[:start]
					period[:end] = period[:start]
					return period
				end
				if current_date > period[:end]
					return period
				end
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
				period = self.leave_period_to_date(current_date)
				return LeavesHolidaysDates.total_leave_days_accumulated(self, period[:start], period[:end])
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
		  	dates_interval = (from_date..to_date).to_a

				user_region = LeavesHolidaysLogic.user_params(self, :region)

				if !include_bank_holidays
					bank_holidays_list = Holidays.between(from_date, to_date, user_region.to_sym, :observed).map{|k| k[:date]}
					dates_interval -= bank_holidays_list
				end

  			dates_interval.delete_if {|i| i.wday == 6 && !include_sat || #delete date from array if day of week is a saturday (6)
              			              i.wday == 0 && !include_sun } #delete date from array if day of week is a sunday (0)

    		return dates_interval.count
			end

			def is_contractor
				self.leave_preferences.is_contractor
			end

			def contract_end_date
				self.leave_preferences.contract_end_date
			end

			def leave_managed_by
				LeavesHolidaysManagements.user_action_actor_list(self, 'sender', 'is_managed_by')
			end

			def leave_consulted_by
				LeavesHolidaysManagements.user_action_actor_list(self, 'sender', 'is_consulted_by')
			end

			def leave_notifies
				LeavesHolidaysManagements.user_action_actor_list(self, 'sender', 'notifies_approved')
			end

			def leave_manages(force_users = false)
				management_rules = LeavesHolidaysManagements.user_action_actor_list(self, 'receiver', 'is_managed_by')
				unless force_users
					return management_rules
				else
					management_user_list = management_rules.select{|r| r.sender.class == User }.map(&:sender)
					management_role_list = management_rules.select{|r| r.sender.class == Role }
					management_user_list += management_role_list.map{|r| r.project.users_for_roles(r.sender) }.flatten
					return management_user_list.uniq
				end
			end

			def leave_users_manage_list
				return LeavesHolidaysManagements.leave_manages_recursive(self) - [self]
			end

			def leave_consults
				LeavesHolidaysManagements.user_action_actor_list(self, 'receiver', 'is_consulted_by')
			end

			def leave_notified_from
				LeavesHolidaysManagements.user_action_actor_list(self, 'receiver', 'notifies_approved')
			end
		end
	end
end

unless User.included_modules.include?(RedmineLeavesHolidays::Patches::UserPatch)
  User.send(:include, RedmineLeavesHolidays::Patches::UserPatch)
end