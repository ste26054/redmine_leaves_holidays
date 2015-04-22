class LeavesHolidaysController < ApplicationController
	unloadable	
	 include LeavesHolidaysLogic

	 @@errors = nil
	# before_filter :issues_list

		def leaves
			Rails.logger.info "METHOD LEAVE"
			@issues_list = issues_list
			
		end

		def create_leave
			@test = LeavesHolidaysTools::new(:leave_from => params[:leave_from],
											 :leave_to => params[:leave_to],
											 :issue_id => params[:issue_selected]	)
			
			unless @test.valid?
				@@errors = @test.errors.messages
				Rails.logger.info "TEST: #{@test.valid?}"
			end
			
			 redirect_to :action => 'leaves'
		end


		private
		#
end