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

			def leave_projects
				return self.projects.active.where(id: LeaveManagementRule.distinct(:project_id).pluck(:project_id))
			end

			# returns the list of projects where the user has a direct leave management rule set 
			def leave_managed_projects
				return LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by').map(&:project).uniq
			end

			# Returns the list of rules where the user appears as a backup
			def leave_backup_rules
			end


			def manage_rules_project(project)
				return LeavesHolidaysManagements.management_rules_list_recursive(self, 'receiver', 'is_managed_by', project)
			end

			def managed_rules_project(project)
				return LeavesHolidaysManagements.management_rules_list_recursive(self, 'sender', 'is_managed_by', project)
			end

			def manage_users_project(project)
				manage_rules = self.manage_rules_project(project)
				manage_users = {directly: [], indirectly: []}


				manage_rules.each_with_index do |rules, nesting| 
		 			users = rules.map(&:to_users).map{|r| r[:user_senders]}.flatten.uniq 
		 			if nesting == 0 
						manage_users[:directly] << users
					else
						manage_users[:indirectly] << users
					end 
				end

				return manage_users
			end

			def managed_users_project(project)
				managed_rules = self.managed_rules_project(project)
				managed_users = {directly: [], indirectly: []}


				managed_rules.each_with_index do |rules, nesting| 
		 			users = rules.map(&:to_users).map{|r| r[:user_senders]}.flatten.uniq 
		 			if nesting == 0 
						managed_users[:directly] << users
					else
						managed_users[:indirectly] << users
					end 
				end

				return managed_users
			end


			def consults_rules_project(project)
				return LeavesHolidaysManagements.management_rules_list(self, 'sender', 'consults', project)
			end

			def consulted_rules_project(project)
				return LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'consults', project)
			end

			def consults_users_project(project)
				consults_rules = self.consults_rules_project(project)
				return consults_rules.map(&:to_users).map{|r| r[:user_receivers]}.flatten.uniq
			end

			def consulted_users_project(project)
				consulted_rules = self.consulted_rules_project(project)
				return consulted_rules.map(&:to_users).map{|r| r[:user_senders]}.flatten.uniq
			end


			def notify_rules_project(project)
				return LeavesHolidaysManagements.management_rules_list(self, 'sender', 'notifies_approved', project)
			end

			def notified_rules_project(project)
				return LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'notifies_approved', project)
			end

			def notify_users_project(project)
				notify_rules = self.notify_rules_project(project)
				return notify_rules.map(&:to_users).map{|r| r[:user_receivers]}.flatten.uniq
			end

			def notified_users_project(project)
				notified_rules = self.notified_rules_project(project)
				return notified_rules.map(&:to_users).map{|r| r[:user_senders]}.flatten.uniq
			end


		end
	end
end

unless User.included_modules.include?(RedmineLeavesHolidays::Patches::UserPatch)
  User.send(:include, RedmineLeavesHolidays::Patches::UserPatch)
end