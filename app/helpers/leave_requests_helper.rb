module LeaveRequestsHelper
	include LeavesHolidaysLogic

	def leaves_holidays_tabs
		tabs = [{:name => 'requests', :partial => 'leave_requests/tab_requests', :label => :tab_my_leaves}]

		if LeavesHolidaysLogic::user_has_any_manage_right(@user)
			tabs.insert 1, {:name => 'approvals', :partial => 'leave_requests/tab_approvals', :label => :tab_leaves_approval}
		end
		tabs << {:name => 'calendar', :partial => 'leave_requests/tab_calendar', :label => :tab_leaves_calendar}
		tabs
	end

	def link_to_month(link_name, year, month, options={})
    	link_to_content_update(h(link_name), params.merge(:year => year, :month => month, :tab => "calendar"), options)
  	end
end
