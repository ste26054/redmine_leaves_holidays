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
		          	joins(:leave_preference).where.not(leave_preferences: { id: nil }).where(:leave_preferences => {is_contractor: 1}) 
		          }

		          scope :cannot_create_leave_request, lambda {
		          	joins(:leave_preference).where.not(leave_preferences: { id: nil }).where(:leave_preferences => {can_create_leave_requests: 0}) 
		          }

							scope :can_create_leave_request, lambda {
								uids = pluck(:id)
		          	cannot_create_request_ids = joins(:leave_preference).where.not(leave_preferences: { id: nil }).where(leave_preferences: {can_create_leave_requests: 0}).pluck(:id)

		          	where(id: uids - cannot_create_request_ids)
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
				#return @leave_preferences if @leave_preferences
				#return @leave_preferences = 
				return LeavePreference.find_by(user_id: self.id) || LeavesHolidaysLogic.get_default_leave_preferences(self)
			end

			def weekly_working_hours
				return self.leave_preferences.weekly_working_hours
			end

			def actual_weekly_working_hours
				lp = self.leave_preferences
				return (lp.weekly_working_hours * lp.overall_percent_alloc) / 100.0 
			end

			def leave_period(current_date = Date.today)
				lp = self.leave_preferences
				return LeavesHolidaysDates.get_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date, false, lp.contract_end_date)
			end
			
			def previous_leave_period(current_date = Date.today)
				lp = self.leave_preferences
				return LeavesHolidaysDates.get_previous_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date, false, lp.contract_end_date)
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
				lp = self.leave_preferences
				return LeavesHolidaysDates.actual_days_max(period[:start], period[:end], lp.annual_leave_days_max, lp.contract_start_date, lp.contract_end_date)
			end

			def days_remaining(current_date = Date.today)
				period = self.leave_period(current_date)
				lp = self.leave_preferences
				return LeavesHolidaysDates.total_leave_days_remaining(self, period[:start], period[:end], self.actual_days_max(current_date), lp.extra_leave_days)
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
				lp = self.leave_preferences
				return LeavesHolidaysDates.total_leave_days_accumulated(period[:start], period[:end], lp.annual_leave_days_max, lp.contract_start_date, lp.contract_end_date)
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

		  # used in redmine_workload_allocation plugin
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

			# returns the list of projects where the user has a direct leave management rule set 
			def leave_managed_projects
				return LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by').map(&:project).uniq
			end			

			def leave_managed_projects_new
				return LeavesHolidaysManagements.management_rules_list_new(self, 'sender', 'is_managed_by').map(&:project).uniq
			end

			# Set of "permissions" based on rules set in the different projects

			# A user can manage leave requests if he manages directly, is set as temporary backup, or is leave admin
			def can_manage_leave_requests
				LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'is_managed_by').any? || self.is_leave_admin?
			end

			def can_manage_leave_requests_project(project)
				LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'is_managed_by', project).any? || self.is_leave_admin?(project)
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

			def can_create_leave_requests
				lp = self.leave_preferences
				return lp.can_create_leave_requests
			end

			# Used in init.rb to check whether user has a link to the plugin displayed
			def has_leave_plugin_access
				can_create_leave_requests || can_manage_leave_requests || can_be_consulted_leave_requests || can_be_notified_leave_requests
			end

			def is_on_leave?(date = Date.today)
				LeaveRequest.overlaps(date, date).includes(:leave_status).where(user_id: self.id, :leave_statuses => {:acceptance_status => LeaveStatus.acceptance_statuses["accepted"]}).any?
			end


			# If user is a leave admin, then he is managed
			def is_managed_in_project?(project)
				LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by', project).any?
			end

			def is_managed?
				LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by').any?
			end

			# A user is managed by a leave admin only if
      # - He can create leave requests
      # - He is not a contractor
      # - He is not a leave admin for the project
      # - He manages people in the project, and does not appear only as a leave backup
      # - He is not managed by anybody in the project
			def is_managed_by_leave_admin?(project)
				return self.can_create_leave_requests && !self.is_managed_in_project?(project) && self.leave_manages_project?(project, false) && !self.is_contractor && !self.is_leave_admin?(project) && !self.is_system_leave_admin?
			end


			def contractor_notifies_leave_admin?(project)
				return self.can_create_leave_requests && self.notify_rules_project(project).empty? && project.leave_management_rules_enabled?
			end

			# returns true if the user manages people on given project
			def leave_manages_project?(project, include_backups = true)
					return LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'is_managed_by', project, [], include_backups).any?
			end

			# Returns the list of project: managers for which the current user is a backup at a given date
			def leave_management_backup_project_list(date = Date.today)
				backup_rule_users = LeaveManagementRule.joins(:leave_exception_rules).where(action: LeaveManagementRule.actions["is_managed_by"], leave_exception_rules: {user_id: self.id, actor_concerned: LeaveExceptionRule.actors_concerned["backup_receiver"]}).flatten.map(&:to_users)

				users_on_leave = LeaveRequest.are_on_leave(backup_rule_users.map{|o| [o[:user_receivers].map(&:id)]}.flatten.uniq, date)

				rule_users_per_project= backup_rule_users.group_by{|r| r[:rule].project}

				managers = {}
				rule_users_per_project.each do |project, rules|
					managers[project] ||= []

					rules.each do |rule|
		        managers[project] << rule[:user_receivers] if rule[:user_receivers].map{|u| u.id.in?(users_on_leave)}.all?
      		end
				end
				return managers.delete_if {|k,v| v == []}
			end

			# Returns who the leave requests will be sent to, taking into account actual date
			def leave_notifications_for_management(date = Date.today)
				users_managing_self_projects = self.managed_users_with_backup_leave(date)
				
				users_to_notify = []
				#obj = {project: nil, users: []}
				#obj = {}
				# For each project where rules are defined for the user
				
				#notify_leave_admin = false

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
						#notify_leave_admin = true
						users_to_notify << project.get_leave_administrators[:users]
					end
				end
				#if notify_leave_admin 
				#	users_to_notify << LeavesHolidaysLogic.plugin_admins_users
				#end

				# Should always send notification to users even if they are on leave. Additional users should be notified in such case.
				return users_to_notify.flatten.uniq
			end

			# Returns if user is a leave admin. 
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

			# Returns all leave projects regarding a user, where:
			# The user is a leave admin OR is a member AND
			# The plugin leave module is enabled AND Leave management rules are enabled.
			def leave_projects
				projects = Project.system_leave_projects
				project_ids_leave_admin = LeavesHolidaysLogic.leave_administrators_for_projects(projects.to_a).select{|k,v| self.in?(v)}.keys.map(&:id)
				project_ids_member = self.projects.system_leave_projects.pluck(:id)

				return Project.where(id: project_ids_leave_admin | project_ids_member)
			end

			# Returns true if given user acts as a backup on the given date
			def is_actually_leave_backup?(date = Date.today)
				#TODO
			end

			# A user who is a project leave administrator can self approve his own requests only if he is not managed anywhere
			def can_self_approve_requests?
				# return false anyway if user is not a leave admin
				return false if !self.is_leave_admin?
				leave_admin_projects = LeaveAdministrator.where(user: self).pluck(:project_id)
				projects_managed = LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by').map(&:project_id)
				return true if (projects_managed - leave_admin_projects).empty?
				return false
			end

		end
	end
end

unless User.included_modules.include?(RedmineLeavesHolidays::Patches::UserPatch)
  User.send(:include, RedmineLeavesHolidays::Patches::UserPatch)
end