module LeavesHolidaysLogic

	def self.issues_list
		Rails.logger.info "IN HELPER ISSUES LIST"
		issues_tracker = RedmineLeavesHolidays::Setting.default_tracker_id
		issues_project = RedmineLeavesHolidays::Setting.default_project_id
		return Issue.where(project_id: issues_project, tracker_id: issues_tracker) #.collect{|t| [t.subject, t.id] }
	end

	def self.roles_list
		Role.find_all_givable.sort.collect{|t| [position: t.position, id: t.id, name: t.name] }
	end

	def self.plugin_admins
		RedmineLeavesHolidays::Setting.plugin_admins.map(&:to_i)
	end

	def self.project_list_for_user(user)
		user.memberships.collect{|t| t.project_id}
	end

	def self.project_roles_for_user(user)
		[]
	end

	def self.is_allowed_to_view_request(user, request)
		return true if user.id == request.user.id
		return true if user.allowed_to?(:view_all_leaves_requests, nil, :global => true) || user.allowed_to?(:manage_leaves_requests, nil, :global => true)
		return true if self.plugin_admins.include?(user.id)
		false
	end

	def self.is_allowed_to_manage_request(user, request)
		return true if user.id == request.user.id #Only the creator of the request can change it
		false
	end

	def self.is_allowed_to_view_status(user, request)
		return true if user.id == request.user.id #A user can see the status of his own requests
		#A user with this right has access to all the leave request statuses
		return true if user.allowed_to?(:view_all_leaves_requests, nil, :global => true) || user.allowed_to?(:manage_leaves_requests, nil, :global => true)
		return true if self.plugin_admins.include?(user.id) 
		false
	end

	def self.is_allowed_to_manage_status(user, request) 
		return true if self.plugin_admins.include?(user.id) #A plugin Admin can approve all the requests including his own requests
		return false if user.id == request.user.id #Any non plugin admin cannot approve his own requests
		if user.allowed_to?(:manage_leaves_requests, nil, :global => true)
			user_req = User.find(request.user.id)
			common_projects = self.project_list_for_user(user) & self.project_list_for_user(user_req)
			Rails.logger.info "COMMON PROJECTS BETWEEN #{user.name} AND #{user_req.name} ARE: #{common_projects}"
			return false if common_projects.empty?
			#TO BE CONTINUED
		end
		false
	end
end