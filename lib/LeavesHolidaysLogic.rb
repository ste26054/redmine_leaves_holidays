module LeavesHolidaysLogic

	def self.issues_list
		issues_tracker = RedmineLeavesHolidays::Setting.defaults_settings(:default_tracker_id)
		issues_project = RedmineLeavesHolidays::Setting.defaults_settings(:default_project_id)
		return Issue.where(project_id: issues_project, tracker_id: issues_tracker) #.collect{|t| [t.subject, t.id] }
	end

	def self.roles_list
		Role.find_all_givable.sort.collect{|t| [position: t.position, id: t.id, name: t.name] }
	end

	def self.plugin_admins
		RedmineLeavesHolidays::Setting.defaults_settings(:default_plugin_admins).map(&:to_i)
	end

	def self.has_manage_rights(user)
		user.allowed_to?(:manage_leaves_requests, nil, :global => true)
	end

	def self.has_vote_rights(user)
		user.allowed_to?(:vote_leaves_requests, nil, :global => true)
	end

	def self.project_list_for_user(user)
		user.memberships.uniq.collect{|t| t.project_id}
	end

	def self.allowed_roles_for_user_for_project(user, project)
		allowed = {}
		allowed[:user_id] = user.id
		allowed_roles = user.roles_for_project(project).sort.uniq
		allowed[:roles] = allowed_roles.collect{|r| { name: r.name, position: r.position, manage: r.allowed_to?(:manage_leaves_requests), vote: r.allowed_to?(:vote_leaves_requests)}}
		return allowed
	end

	def self.is_allowed_to_view_request(user, request)
		return true if user.id == request.user.id
		return false if request.request_status == "created"
		return true if user.allowed_to?(:view_all_leaves_requests, nil, :global => true) || user.allowed_to?(:manage_leaves_requests, nil, :global => true) || user.allowed_to?(:vote_leaves_requests, nil, :global => true)
		return true if self.plugin_admins.include?(user.id)
		false
	end


	def self.is_allowed_to_edit_request(user, request)
		return true if user.id == request.user.id #Only the creator of the request can change it
		false
	end

	def self.is_allowed_to_view_status(user, user_request)
		return true if user.id == user_request.id #A user can see the status of his own requests
		#A user with this right has access to all the leave request statuses
		return true if user.allowed_to?(:view_all_leaves_requests, nil, :global => true) || user.allowed_to?(:manage_leaves_requests, nil, :global => true)
		return true if self.plugin_admins.include?(user.id) 
		false
	end

	def self.is_allowed_to_manage_status(user, user_request)
		return true if self.plugin_admins.include?(user.id) #A plugin Admin can approve all the requests including his own requests
		return true if user.id == user_request.id && self.user_params(user, :is_contractor) == true
		return false if !user.allowed_to?(:manage_leaves_requests, nil, :global => true)
		return false if self.plugin_admins.include?(user_request.id) #User req is plugin admin and hence his role >>> user -> Disallow
		return false if user.id == user_request.id #Any non plugin admin cannot approve his own requests

		common_projects = self.project_list_for_user(user) & self.project_list_for_user(user_request)
		if !common_projects.empty?
			common_projects.each do |p|
				project = Project.find(p)
				array_roles_user = (self.allowed_roles_for_user_for_project(user, project))
				array_roles_user_req = (self.allowed_roles_for_user_for_project(user_request, project))
				array_roles_user[:roles].each do |role|
					if (role[:position] < array_roles_user_req[:roles].first[:position]) && role[:manage]
						return true
					end
				end
			end
			
		end
		false
	end

	def self.is_allowed_to_vote_request(user, user_request)
		role = {}
		# return true
		return role if user.id == user_request.id #A user cannot vote for his own leave request
		#  DEBUG ONLY
		#return true if self.plugin_admins.include?(user.id)
		return role if !user.allowed_to?(:vote_leaves_requests, nil, :global => true)
		common_projects = self.project_list_for_user(user) & self.project_list_for_user(user_request)
		if !common_projects.empty?
			common_projects.each do |p|
				project = Project.find(p)
				array_roles_user = (self.allowed_roles_for_user_for_project(user, project))
				array_roles_user_req = (self.allowed_roles_for_user_for_project(user_request, project))
				array_roles_user[:roles].each do |role|
					if (role[:position] < array_roles_user_req[:roles].first[:position]) && role[:vote] && !role[:manage]
						return role
					end
				end
			end
			
		end
		role
	end

	def self.user_role_details(user, user_request)
		user_role_details = {}

		if self.plugin_admins.include?(user.id) #A plugin Admin can approve all the requests including his own requests
			user_role_details[:user_id] = user.id
			user_role_details[:role_position] = 0
			return user_role_details
		end
		return user_role_details if !user.allowed_to?(:manage_leaves_requests, nil, :global => true)
		return user_role_details if self.plugin_admins.include?(user_request.id) #User req is plugin admin and hence his role >>> user -> Disallow
		return user_role_details if user.id == user_request.id #Any non plugin admin cannot approve his own requests

		common_projects = self.project_list_for_user(user) & self.project_list_for_user(user_request)
		if !common_projects.empty?
			common_projects.each do |p|
				project = Project.find(p)
				array_roles_user = (self.allowed_roles_for_user_for_project(user, project))
				array_roles_user_req = (self.allowed_roles_for_user_for_project(user_request, project))
				array_roles_user[:roles].each do |role|
					if (role[:position] < array_roles_user_req[:roles].first[:position]) && role[:manage]
						user_role_details[:user_id] = array_roles_user[:user_id]
						user_role_details[:role_position] = role[:position]
						return user_role_details
					end
					# return true if (role[:position] < array_roles_user_req.first[:position]) && role[:allowed]
				end
			end
			
		end
		user_role_details
	end

	#Returns a list of users which are able to approve a leave request
	def self.can_approve_request(user_request)
		users = User.where(status: 1)
		users = users.collect {|t| {uid: t.id, name: t.name, role_details: self.user_role_details(t, user_request) }}

		users.delete_if { |u| 
			u[:role_details].empty?
		}
		return users.sort_by { |e| -e[:role_details][:role_position].to_i }
	end

	#Returns a list of users to notify of a leave request. 
	def self.users_to_notify_of_request(user_request)
		notification_level = RedmineLeavesHolidays::Setting.defaults_settings(:default_notification_level).to_i
		users = self.can_approve_request(user_request)
		users_to_notify = users.dup
		users = users.sort_by { |e| e[:role_details][:role_position].to_i }.reverse!
		roles = users.map { |e| e[:role_details][:role_position].to_i }.uniq.first(notification_level)
		users_to_notify.delete_if { |u| !roles.include?(u[:role_details][:role_position].to_i) || u[:role_details][:user_id].to_i == user_request.id }
		users_to_notify.sort_by { |e| -e[:role_details][:role_position].to_i }
	end

	def self.get_region_list
		Holidays.load_all
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

		role = {}

		common_projects = self.project_list_for_user(user) & self.project_list_for_user(user_request)
		if !common_projects.empty?
			common_projects.each do |p|
				project = Project.find(p)
				array_roles_user = (self.allowed_roles_for_user_for_project(user, project))
				array_roles_user_req = (self.allowed_roles_for_user_for_project(user_request, project))
				array_roles_user[:roles].each do |role|
					case mode
					when 1
						if (role[:position] < array_roles_user_req[:roles].first[:position]) && (role[:vote] || role[:manage])
							return role
						end
					when 2
						if (role[:position] < array_roles_user_req[:roles].first[:position]) && (role[:vote] && !role[:manage])
							return role
						end
					when 3
						if (role[:position] < array_roles_user_req[:roles].first[:position]) && (role[:manage])
							return role
						end
					else
					end
				end
			end
		end
		return role
	end

	def self.has_right(user_accessor, user_owner, object, action)

		Rails.logger.info "IN HAS RIGHTS: #{user_accessor}, #{user_owner}, #{object}, #{action}"
		object_list = [LeavePreference, LeaveRequest, LeaveStatus, LeaveVote]
	 	action_list = [:create, :read, :update, :delete, :cancel, :submit, :unsubmit]

	 	# Rename supefluous actions from controllers
	 	if !action.in?(action_list)
	 		action = :create if action == :new
	 		action = :read if action == :show
	 		action = :update if action == :edit 
	 		action = :delete if action == :destroy
	 	end

		raise ArgumentError, 'Argument is not a user' unless user_accessor.is_a?(User)
		raise ArgumentError, 'Argument is not a user' unless user_owner.is_a?(User)
		raise ArgumentError, "Argument is not a leave object: #{object.class}" unless object.class.in?(object_list) || object.in?(object_list)
		raise ArgumentError, 'Argument is not a valid action' unless action.in?(action_list)

		case object
		when LeavePreference
			if action == :cancel
				return false
			else
				if action.in?([:create, :read, :update, :delete])
					if self.plugin_admins.include?(user_accessor.id) || user_accessor.allowed_to?(:manage_user_leaves_preferences, nil, :global => true)
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

		when LeaveRequest 
			leave = object
			return true if action == :create
			return false if leave.request_status == "cancelled"
			if action == :read
				return true if user_accessor.id == user_owner.id
				if leave.request_status.in?(["submitted", "processing", "processed"])
					if self.plugin_admins.include?(user_accessor.id) || !self.allowed_common_project(user_accessor, user_owner, 1).empty?
						return true
					else
						if leave.request_status == "processed"
							return true if user_accessor.allowed_to?(:view_all_leaves_requests, nil, :global => true)
						end
					end
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

		when LeaveVote
			vote = object
			leave = vote.leave_request

			if action == :create
				if leave.request_status.in?(["submitted", "processing"])
					return true if !self.allowed_common_project(user_accessor, user_owner, 2).empty?
				end
			end
			if leave.request_status == "processing"	
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
				if action == :update
					return true if user_accessor.id == user_owner.id && !self.allowed_common_project(user_accessor, user_owner, 2).empty?
				end
			end

		when LeaveStatus
			status = object
			leave = status.leave_request
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
					return true if user_accessor.allowed_to?(:view_all_leaves_requests, nil, :global => true)
				end
			end
		else

		end
		return false
	end



end