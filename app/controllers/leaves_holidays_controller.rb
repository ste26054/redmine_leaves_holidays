class LeavesHolidaysController < ApplicationController
	unloadable	
	 include LeavesHolidaysLogic

	# before_filter :issues_list

		def leaves
			Rails.logger.info "METHOD LEAVE"
			@issues_list = issues_list
			
		end

		def create_leave
			@test = LeavesHolidaysTools::new()
			@test.issue_correct?
			redirect_to :action => 'leaves'
		end


		private
		#
end