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

		          scope :contractor, lambda {
		          	joins(:leave_preference).where(:leave_preferences => {is_contractor: 1}) 
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
			include LeavesCommonUserRole

			def leave_preferences
				LeavePreference.find_by(user_id: self.id) || LeavesHolidaysLogic.get_default_leave_preferences(self)
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

			def overall_percent_alloc
				self.leave_preferences.overall_percent_alloc
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

			# Set of "permissions" based on rules set in the different projects

			def can_manage_leave_requests
				!LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'is_managed_by').empty?
			end

			def can_manage_leave_requests_project(project)
				!LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'is_managed_by', project).empty?
			end

			def can_be_consulted_leave_requests
				!LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'consults').empty?
			end

			def can_be_notified_leave_requests
				!LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'notifies_approved').empty?
			end

			def can_be_notified_leave_requests_project(project)
				!LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'notifies_approved', project).empty?
			end

			# TBC with permissions above
			def can_create_leave_requests
				!LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by').empty? || is_contractor || can_manage_leave_requests || can_be_notified_leave_requests ||  self.id.in?(LeavesHolidaysLogic.plugin_admins)
			end

			def can_create_leave_requests_project(project)
				!LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by', project).empty? || can_manage_leave_requests_project(project) || can_be_notified_leave_requests_project(project) || self.id.in?(LeavesHolidaysLogic.plugin_admins)
			end

			def has_leave_plugin_access
				can_create_leave_requests || can_manage_leave_requests || can_be_consulted_leave_requests || can_be_notified_leave_requests
			end

			def is_on_leave?(date = Date.today)
				LeaveRequest.overlaps(date, date).includes(:leave_status).where(user_id: self.id, :leave_statuses => {:acceptance_status => LeaveStatus.acceptance_statuses["accepted"]}).any?
			end

			def is_managed_in_project?(project)
				LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by', project).any?
			end

			def is_managed?
				LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by').any?
			end


			# Returns who the leave requests will be sent to, taking into account actual date
			def leave_notifications_for_management(date = Date.today)
				users_managing_self_projects = self.managed_users_with_backup_leave(date)
				
				users_to_notify = []
				#obj = {project: nil, users: []}
				#obj = {}
				# For each project where rules are defined for the user
				
				#notify_plugin_admin = false

				users_managing_self_projects.each do |project, user_arrays|
					nesting = 0
					user_arrays.each do |users|
						size = users.size
						on_leave = users.select{|u| u[:is_on_leave] == true }.size
						users_to_notify << users.map{|u| u[:user] }
						if size != on_leave
							break
						else
							nesting += 1
						end
					end
					if nesting == user_arrays.size
						#notify_plugin_admin = true
						users_to_notify << project.get_leave_administrators[:users]
					end
				end
				#if notify_plugin_admin 
				#	users_to_notify << LeavesHolidaysLogic.plugin_admins_users
				#end

				# Should always send notification to users even if they are on leave. Additional users should be notified in such case.
				return users_to_notify.flatten.uniq
			end

			def is_leave_admin?(project = nil)
				return false if !self.active?
				if project != nil
					return self.in?(project.get_leave_administrators[:users])
				else
					return self.in?(LeavesHolidaysLogic.plugin_admins_users) || self.in?(LeaveAdministrator.all.includes(:user).map{|l| l.user})
				end
			end

			def is_system_leave_admin?
				return self.id.in?(LeavesHolidaysLogic.plugin_admins)
			end

			def is_project_leave_admin?(project)
				return false if project == nil
				return self.in?(project.get_leave_administrators[:users])
			end

			def notify_leave_admin(project)
				if self.is_contractor
					return self.notify_rules_project(project).empty?
				else
					return self.managed_rules_project(project).empty? && self.notify_rules_project(project).empty?
				end
			end

		end
	end
end

unless User.included_modules.include?(RedmineLeavesHolidays::Patches::UserPatch)
  User.send(:include, RedmineLeavesHolidays::Patches::UserPatch)
end