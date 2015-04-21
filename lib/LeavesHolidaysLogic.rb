module LeavesHolidaysLogic

	def issues_list
		Rails.logger.info "IN HELPER ISSUES LIST"
		issues_tracker = RedmineLeavesHolidays::Setting.default_tracker_id
		issues_project = RedmineLeavesHolidays::Setting.default_project_id
		return Issue.where(project_id: issues_project, tracker_id: issues_tracker).collect{|t| [t.subject, t.id] }
	end

end