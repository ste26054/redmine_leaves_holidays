module LeavesHolidaysLogic
	using LeavesHolidaysExtensions

	def self.issues_list
		issues_tracker = RedmineLeavesHolidays::Setting.defaults_settings(:default_tracker_id)
		issues_project = RedmineLeavesHolidays::Setting.defaults_settings(:default_project_id)
		return Issue.where(project_id: issues_project, tracker_id: issues_tracker)
	end

	def self.roles_list
		Role.find_all_givable.sort.collect{|t| [position: t.position, id: t.id, name: t.name] }
	end

	def self.plugin_admins
		RedmineLeavesHolidays::Setting.defaults_settings(:default_plugin_admins).map(&:to_i)
	end

	def self.plugin_admins_users
		ids = RedmineLeavesHolidays::Setting.defaults_settings(:default_plugin_admins).map(&:to_i)
		return User.find(ids)
	end

	def self.has_manage_rights(user)
		user.allowed_to?(:manage_leave_requests, nil, :global => true)
	end

	def self.has_vote_rights(user)
		user.allowed_to?(:consult_leave_requests, nil, :global => true)
	end

	def self.has_view_all_rights(user)
		user.allowed_to?(:view_all_leave_requests, nil, :global => true)
	end

	def self.user_has_rights(user, rights)
		if !rights.is_a?(Array)
			rights = [rights]
		end
		rights.each do |right|
			return false if !user.allowed_to?(right, nil, :global => true)
		end
		return true
	end

	def self.user_has_any_manage_right(user)
		return self.has_manage_rights(user) || self.has_vote_rights(user) || self.has_view_all_rights(user) || self.plugin_admins.include?(user.id)
	end

	def self.users_rights_list(rights)
		users = User.where(status: 1)
		allowed = []
		users.each do |user|
			if self.user_has_rights(user,rights)
				allowed  << user
			end
		end
		return allowed
	end

	def self.project_list_for_user(user)
		user.memberships.uniq.collect{|t| t.project_id}
	end

	def self.allowed_roles_for_user_for_project(user, project)
		allowed = {}
		allowed_roles = user.roles_for_project(project).sort.uniq
		allowed = allowed_roles.collect{|r| { user: user, user_id: user.id, project: project.name, project_id: project.id, name: r.name, position: r.position, manage: r.allowed_to?(:manage_leave_requests), vote: r.allowed_to?(:consult_leave_requests)}}
		return allowed
	end

	def self.get_region_list
		return Holidays.regions.sort
	end

	def self.user_params(user, arg)
		prefs = LeavePreference.where(user_id: user.id).first
		return prefs.send(arg) if prefs != nil
		RedmineLeavesHolidays::Setting.defaults_settings(arg)
	end

	def self.allowed_common_project(user, user_request, mode)
		#Modes: 1, 2, 3
		#1 - role has Manage OR Vote
		#2 - role has Vote AND not Manage
		#3 - role has Manage
		roles = []
		role = {}

		common_projects = self.project_list_for_user(user) & self.project_list_for_user(user_request)
		if !common_projects.empty?
			common_projects.each do |p|
				project = Project.find(p)
				array_roles_user = (self.allowed_roles_for_user_for_project(user, project))
				array_roles_user_req = (self.allowed_roles_for_user_for_project(user_request, project))
				array_roles_user.each do |role|
					case mode
					when 1
						if (role[:position] < array_roles_user_req.first[:position]) && (role[:vote] || role[:manage])
							roles << role
						end
					when 2
						if (role[:position] < array_roles_user_req.first[:position]) && (role[:vote] && !role[:manage])
							roles << role
						end
					when 3
						if (role[:position] < array_roles_user_req.first[:position]) && (role[:manage])
							roles << role
						end
					else
					end
				end
			end
		end
		return roles
	end

	def self.users_allowed_common_project(user_request, mode)
		users = User.where(status: 1)
		allowed = []
		users.each do |user|
			if user.id != user_request.id
				res = []
				res = self.allowed_common_project(user, user_request, mode)
				unless res.empty?
					allowed  << res
				end
			end
		end
		return allowed
	end

	def self.has_right(user_accessor, user_owner, object, action, leave_request = nil)

		object_list = [LeavePreference, LeaveRequest, LeaveStatus, LeaveVote]
	 	action_list = [:create, :read, :update, :delete, :cancel, :submit, :unsubmit, :index]

	 	# Rename superfluous actions from controllers
	 	if !action.in?(action_list)
	 		action = :create if action == :new
	 		action = :read if action == :show
	 		action = :read if action == :index
	 		action = :update if action == :edit 
	 		action = :delete if action == :destroy
	 	end

		raise ArgumentError, 'Argument is not a user' unless user_accessor.is_a?(User)
		raise ArgumentError, 'Argument is not a user' unless user_owner.is_a?(User)
		raise ArgumentError, "Argument is not a leave object: #{object.class}" unless object.class.in?(object_list) || object.in?(object_list)
		raise ArgumentError, 'Argument is not a valid action' unless action.in?(action_list)


		if object == LeavePreference || object.class == LeavePreference
			if action == :cancel
				return false
			else
				if action.in?([:create, :read, :update, :delete])
					if self.plugin_admins.include?(user_accessor.id) || user_accessor.allowed_to?(:manage_user_leave_preferences, nil, :global => true)
						return true
					else
						if action == :read
							if user_accessor.id == user_owner.id || !self.allowed_common_project(user_accessor, user_owner, 1).empty?
								return true
							end
						end
					end	
				end
			end
		end

		if object == LeaveRequest || object.class == LeaveRequest
			if leave_request == nil
				leave = object
			else
				leave = leave_request
			end
			return true if action == :create
			# return false if leave.request_status == "cancelled"
			if action == :read
				return true if user_accessor.id == user_owner.id
				if leave.request_status.in?(["submitted", "processing", "processed"])
					if self.plugin_admins.include?(user_accessor.id) || !self.allowed_common_project(user_accessor, user_owner, 1).empty?
						return true
					else
						if leave.request_status == "processed"
							return true if user_accessor.allowed_to?(:view_all_leave_requests, nil, :global => true)
						end
					end
				else
					return true if user_accessor.allowed_to?(:view_all_leave_requests, nil, :global => true) || self.plugin_admins.include?(user_accessor.id) || !self.allowed_common_project(user_accessor, user_owner, 1).empty?
				end
			end
			if user_accessor.id == user_owner.id
				if action == :update || action == :submit
					return true if leave.request_status == "created"
				end
				if action == :delete
					return true
				end
				if action == :unsubmit
					return true if leave.request_status == "submitted"
				end
			end
		end
		if object == LeaveVote || object.class == LeaveVote
			vote = object
			if (defined?(vote.leave_request)).nil?
				leave = leave_request
			else
				leave = vote.leave_request
			end
			return false if leave.user_id == user_accessor.id

			if action == :create
				if leave.request_status.in?(["submitted", "processing"])
					return true if !self.allowed_common_project(user_accessor, user_owner, 2).empty?
				end
			end
			if leave.request_status.in?(["processing", "processed"])
				if action == :read
					if self.plugin_admins.include?(user_accessor.id)
						return true
					end
					if !self.allowed_common_project(user_accessor, user_owner, 2).empty?
						return true
					end
					if !self.allowed_common_project(user_accessor, user_owner, 3).empty?
						return true
					end
				end
				if action == :update && leave.request_status == "processing"

					return true if user_accessor.id == user_owner.id# && !self.allowed_common_project(user_accessor, user_owner, 2).empty?
				end
			end
		end
		if object == LeaveStatus || object.class == LeaveStatus
			status = object
			if (defined?(status.leave_request)).nil?
				leave = leave_request
			else
				leave = status.leave_request
			end
			# return true if user_accessor.id == user_owner.id && self.user_params(user_accessor, :is_contractor)
			if action == :create
				if leave.request_status.in?(["submitted", "processing"])
					return true if self.plugin_admins.include?(user_accessor.id) || !self.allowed_common_project(user_accessor, user_owner, 3).empty?
				end
			end
			if leave.request_status == "processed"
				if action.in?([:read, :update])
					return true if self.plugin_admins.include?(user_accessor.id)
					return true if !self.allowed_common_project(user_accessor, user_owner, 3).empty?
				end
				if action == :read
					return true if user_accessor.id == user_owner.id
					return true if user_accessor.allowed_to?(:view_all_leave_requests, nil, :global => true)
				end
			end
		end
		return false
	end

	def self.has_rights(user_accessor, user_owner, objects, actions, leave_request = nil, criteria)
		if !objects.is_a?(Array)
			objects = [objects]
		end

		objects.each do |object|
			actions.each do |action|
				return true if criteria == :or && self.has_right(user_accessor, user_owner, object, action, leave_request)
				return false if criteria == :and && !self.has_right(user_accessor, user_owner, object, action, leave_request)
			end
		end
		return false if criteria == :or
		return true if criteria == :and
	end

	def self.vote_list_left(leave_request)
		list = LeavesHolidaysLogic.users_allowed_common_project(leave_request.user, 2)
		if leave_request == nil
			return list
		else
			list.delete_if { |u| !LeaveVote.for_request(leave_request.id).for_user(u.first[:user_id]).empty? }
		end
		return list
	end

	def self.vote_list(leave_request)
		return LeavesHolidaysLogic.users_allowed_common_project(leave_request.user, 2)
	end	

	def self.manage_list(leave_request)
		return LeavesHolidaysLogic.users_allowed_common_project(leave_request.user, 3)
	end

	def self.retrieve_leave_preferences(user)
      p = LeavePreference.new
      p.weekly_working_hours = RedmineLeavesHolidays::Setting.defaults_settings(:weekly_working_hours)
      p.annual_leave_days_max = RedmineLeavesHolidays::Setting.defaults_settings(:annual_leave_days_max)
      p.region = RedmineLeavesHolidays::Setting.defaults_settings(:region)
      p.contract_start_date = RedmineLeavesHolidays::Setting.defaults_settings(:contract_start_date)
      p.extra_leave_days = 0.0
      p.is_contractor = RedmineLeavesHolidays::Setting.defaults_settings(:is_contractor)
      p.user_id = user.id
      p.annual_max_comments = ""
      p.leave_renewal_date = RedmineLeavesHolidays::Setting.defaults_settings(:leave_renewal_date)
      return p
  end

end