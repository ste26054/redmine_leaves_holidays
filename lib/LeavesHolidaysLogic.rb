module LeavesHolidaysLogic

	def issues_list
		Rails.logger.info "IN HELPER ISSUES LIST"
		issues_tracker = RedmineLeavesHolidays::Setting.default_tracker_id
		issues_project = RedmineLeavesHolidays::Setting.default_project_id
		return Issue.where(project_id: issues_project, tracker_id: issues_tracker) #.collect{|t| [t.subject, t.id] }
	end

	def roles_list
		Role.find_all_givable.sort.collect{|t| [position: t.position, id: t.id, name: t.name] }
	end

	def self.is_allowed_to_view_request(user, request)
		return false unless user.id == request.user.id
		true
	end

	def self.is_allowed_to_manage_request(user, request)
		return false unless self.is_allowed_to_view_request(user, request)
		true
	end

	def self.is_allowed_to_view_status(user, request)
		true
	end

	def self.is_allowed_to_manage_status(user, request)
		true
	end
end