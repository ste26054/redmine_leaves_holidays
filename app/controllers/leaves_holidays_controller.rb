class LeavesHolidaysController < ApplicationController
	unloadable	

	before_filter :issues_list

		def leaves
			Rails.logger.info "METHOD LEAVE"

			
		end

		def create_leave
			Rails.logger.info  "*************** METHOD CREATE ***********************"
			@test = LeavesHolidays.new()

			Rails.logger.info  "EXISTS: #{@test.exists?}"
			redirect_to :action => 'leaves'
		end


		private

		def issues_list
			issues_tracker = RedmineLeavesHolidays::Setting.default_tracker_id
			issues_project = RedmineLeavesHolidays::Setting.default_project_id
			@issues_list = Issue.where(project_id: issues_project, tracker_id: issues_tracker).collect{|t| [t.subject, t.id] };
		end

end