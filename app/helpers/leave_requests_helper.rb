module LeaveRequestsHelper
	include LeavesHolidaysLogic

	def render_leave_tabs(tabs, selected=params[:tab])
	    if tabs.any?
	      unless tabs.detect {|tab| tab[:name] == selected}
	        selected = nil
	      end
	      selected ||= tabs.first[:name]
	      render :partial => 'leave_commons/tabs', :locals => {:tabs => tabs, :selected_tab => selected}
	    else
	      content_tag 'p', l(:label_no_data), :class => "nodata"
	    end
	end

	def leaves_holidays_tabs
		tabs = [{:name => 'requests', :label => :tab_my_leaves, :controller => 'leave_requests', :action => 'index'}]

		if LeavesHolidaysLogic::user_has_any_manage_right(@user)
			tabs.insert 1, {:name => 'approvals', :label => :tab_leaves_approval, :controller => 'leave_approvals', :action => 'index'}
		end
		tabs << {:name => 'calendar', :label => :tab_leaves_calendar, :controller => 'leave_calendars', :action => 'show'}
		tabs
	end

	def link_to_month(link_name, year, month, options={})
    	link_to_content_update(h(link_name), params.merge(:year => year, :month => month, :tab => "calendar"), options)
  	end
end
