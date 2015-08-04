module LeaveRequestsHelper
	include LeavesHolidaysLogic

	def render_leave_tabs(tabs, selected=params[:tab])
	    if tabs.any?
	      unless tabs.detect {|tab| tab[:controller] == selected}
	        selected = nil
	      end
	      selected ||= tabs.first[:controller]
	      render :partial => 'leave_commons/tabs', :locals => {:tabs => tabs, :selected_tab => selected}
	    else
	      content_tag 'p', l(:label_no_data), :class => "nodata"
	    end
	end

	def leaves_holidays_tabs
		tabs = []
		tabs << {:label => :tab_my_leaves, :controller => 'leave_requests', :action => 'index'}

		if LeavesHolidaysLogic::user_has_any_manage_right(@user)
			tabs << { :label => :tab_leaves_approval, :controller => 'leave_approvals', :action => 'index'}
		end

		tabs << {:label => :tab_leaves_calendar, :controller => 'leave_calendars', :action => 'show'}
		return tabs
	end

end
