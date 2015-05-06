module LeaveRequestsHelper
	include LeavesHolidaysLogic

	def leaves_holidays_tabs
		tabs = [{:name => 'requests', :partial => 'leave_requests/tab_requests', :label => :tab_my_leaves}]

		if LeavesHolidaysLogic::has_manage_rights(User.current)
			tabs.insert 1, {:name => 'approvals', :partial => 'leave_requests/tab_approvals', :label => :tab_leaves_approval}
		end
		tabs
	end
end
