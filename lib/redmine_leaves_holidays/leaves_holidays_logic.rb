using LeavesHolidaysExtensions #local patch of user methods 
module LeavesHolidaysLogic

	def self.leave_metrics_for_users(users, current_date = Date.today)
		user_ids = users.map(&:id)
		leave_preferences = LeavePreference.where(user_id: user_ids).includes(:user)#.to_a
		default_lp = self.get_default_leave_preferences

		users_with_lp = leave_preferences.map(&:user)
		users_without_lp = users - users_with_lp

		users = {}

		leave_preferences.find_each do |lp|
			user = {}
			leave_period = LeavesHolidaysDates.get_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date, false, lp.contract_end_date)
			leave_period_to_date = LeavesHolidaysDates.get_leave_period_to_date(leave_period[:start], leave_period[:end], current_date)

			user[:date] = current_date
			user[:leave_preferences] = lp
			user[:leave_period] = leave_period
			user[:leave_period_to_date] = leave_period_to_date
			user[:actual_days_max] = LeavesHolidaysDates.actual_days_max(leave_period[:start], leave_period[:end], lp.annual_leave_days_max, lp.contract_start_date, lp.contract_end_date)
			user[:days_accumulated] = LeavesHolidaysDates.total_leave_days_accumulated(leave_period_to_date[:start], leave_period_to_date[:end], lp.annual_leave_days_max, lp.contract_start_date, lp.contract_end_date)
			user[:days_remaining] = LeavesHolidaysDates.total_leave_days_remaining(lp.user, leave_period[:start], leave_period[:end], user[:actual_days_max], lp.extra_leave_days)
			user[:days_taken] = user[:actual_days_max] + lp.extra_leave_days - user[:days_remaining]
			users[lp.user] = user
		end

		default_leave_period = LeavesHolidaysDates.get_leave_period(default_lp.contract_start_date, default_lp.leave_renewal_date, current_date, false)
		default_leave_period_to_date = LeavesHolidaysDates.get_leave_period_to_date(default_leave_period[:start], default_leave_period[:end], current_date)
		
		default_actual_days_max = LeavesHolidaysDates.actual_days_max(default_leave_period[:start], default_leave_period[:end], default_lp.annual_leave_days_max, default_lp.contract_start_date)
		
		default_days_accumulated = LeavesHolidaysDates.total_leave_days_accumulated(default_leave_period_to_date[:start], default_leave_period_to_date[:end], default_lp.annual_leave_days_max, default_lp.contract_start_date, default_lp.contract_end_date)

		users_without_lp.each do |usr|
			user = {}
			user[:date] = current_date
			user[:leave_preferences] = default_lp
			user[:leave_period] = default_leave_period
			user[:leave_period_to_date] = default_leave_period_to_date
			user[:actual_days_max] = default_actual_days_max
			user[:days_accumulated] = default_days_accumulated
			user[:days_remaining] = LeavesHolidaysDates.total_leave_days_remaining(usr, default_leave_period[:start], default_leave_period[:end], user[:actual_days_max], 0)
			user[:days_taken] = user[:actual_days_max] - user[:days_remaining]
			users[usr] = user
		end

		return users
	end

	def self.leave_administrators_for_projects(projects)
		project_leave_administrators = LeaveAdministrator.includes(:user, :project).where(project: projects).group_by(&:project)
		projects_with_administrators = project_leave_administrators.keys
		projects_without_administrators = projects - projects_with_administrators
		system_leave_admins = self.plugin_admins_users

		out = {}

		projects_with_administrators.each do |project|
			out[project] = project_leave_administrators[project].map(&:user)
		end

		projects_without_administrators.each do |project|
			out[project] = system_leave_admins
		end

		return out
	end

	def self.users_for_projects(project_list)
		project_ids = project_list.map(&:id)
		user_ids = Member.select(:user_id).distinct.joins(:user).where(project_id: project_ids).where.not(users: {id: nil}).pluck(:user_id)
		return User.where(id: user_ids, status: 1)
	end

	def self.users_with_roles_for_projects(role_list, project_list)
		project_ids = project_list.map(&:id)
		role_ids = role_list.map(&:id)
		user_ids = Member.joins(:roles, :user).where(member_roles: {role_id: role_ids}, project_id: project_ids).where.not(users: {id: nil}).pluck(:user_id).uniq
		return User.where(id: user_ids)
	end

  def self.get_working_days_count(from_date, to_date, region, include_sat = false, include_sun = false, include_bank_holidays = false)
		dates_interval = (from_date..to_date).to_a

		if !include_bank_holidays
			bank_holidays_list = Holidays.between(from_date, to_date, region.to_sym, :observed).map{|k| k[:date]}
			dates_interval -= bank_holidays_list
		end

		dates_interval.delete_if {|i| i.wday == 6 && !include_sat || #delete date from array if day of week is a saturday (6)
	        			              i.wday == 0 && !include_sun } #delete date from array if day of week is a sunday (0)

		return dates_interval.count
	end

	# returns projects where the leave_management module is activated.
	def self.projects_with_leave_management_active
		return Project.all.active.where(id: EnabledModule.where(name: "leave_management").pluck(:project_id))
	end
	
	def self.issues_list(user = nil)
		issues_tracker = RedmineLeavesHolidays::Setting.defaults_settings(:default_tracker_id)
		issues_project = RedmineLeavesHolidays::Setting.defaults_settings(:default_project_id)
		issues = Issue.where(project_id: issues_project, tracker_id: issues_tracker)
		return issues unless user
		
		if user.is_contractor
			return issues.where(id: RedmineLeavesHolidays::Setting.defaults_settings(:available_reasons_contractors).map(&:to_i))
		else
			return issues.where(id: RedmineLeavesHolidays::Setting.defaults_settings(:available_reasons_non_contractors).map(&:to_i))
		end
	end

	def self.plugin_admins
		out = RedmineLeavesHolidays::Setting.defaults_settings(:default_plugin_admins) || []
		out.map(&:to_i)
	end

	def self.plugin_admins_users
		ids = RedmineLeavesHolidays::Setting.defaults_settings(:default_plugin_admins) || []
		return User.active.where(id: ids.map(&:to_i)).to_a.uniq
	end	

	def self.plugin_users_errors_recipients
		ids = RedmineLeavesHolidays::Setting.defaults_settings(:leave_error_recipients) || []
		return User.active.where(id: ids.map(&:to_i)).to_a.uniq
	end

	def self.has_view_all_rights(user)
		user.allowed_to?(:view_all_leave_requests, nil, :global => true)
	end

	def self.get_region_list
		return RedmineLeavesHolidays::Setting.defaults_settings(:available_regions) || []
	end

	def self.user_params(user, arg)
		prefs = LeavePreference.where(user_id: user.id).first
		return prefs.send(arg) if prefs != nil
		RedmineLeavesHolidays::Setting.defaults_settings(arg)
	end


	def self.get_default_leave_preferences(user = nil)
    p = LeavePreference.new
    p.weekly_working_hours = RedmineLeavesHolidays::Setting.defaults_settings(:weekly_working_hours)
    p.annual_leave_days_max = RedmineLeavesHolidays::Setting.defaults_settings(:annual_leave_days_max)
    p.region = RedmineLeavesHolidays::Setting.defaults_settings(:region)
    p.contract_start_date = RedmineLeavesHolidays::Setting.defaults_settings(:contract_start_date)
    p.extra_leave_days = 0.0
    p.is_contractor = RedmineLeavesHolidays::Setting.defaults_settings(:is_contractor)
    p.user_id = user.id if user
    p.annual_max_comments = ""
    p.leave_renewal_date = RedmineLeavesHolidays::Setting.defaults_settings(:leave_renewal_date)
    p.overall_percent_alloc = 100
    p.can_create_leave_requests = true
    return p
  end

  def self.users_with_view_all_right
		# Get roles allowed to manage
		role_ids = Role.where("permissions LIKE ?", "%:view_all_leave_requests%").pluck(:id)
		
		# Get member role ids of roles allowed to manage
		member_role_ids = MemberRole.where(role_id: role_ids).pluck(:id)

		# Get the uniq user ids of corresponding members
		return Member.includes(:member_roles, :project, :user).where(member_roles: {id: member_role_ids}, users: {status: 1}).where(project_id: self.projects_with_leave_management_active.pluck(:id)).map(&:user).uniq
	end

end