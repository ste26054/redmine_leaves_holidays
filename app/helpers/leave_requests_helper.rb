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

	def leaves_status_options_for_select(status_count, selected)
		options_for_select([["submitted (#{status_count[1].to_i})", '1'],
	                        ["processing (#{status_count[4].to_i})", '4'],
	                        ["processed (#{status_count[2].to_i})", '2']], selected)
 	end

 	def leaves_regions_options_for_select(selected)
 		options = LeaveRequest.group('region').count.to_hash.keys.collect {|k| [k, k]}
	    options_for_select(options, selected)
 	end

 	def leaves_dates_options_for_select(selected)
	    options_for_select([["finished", 'finished'],
	                        ["ongoing", 'ongoing'],
	                        ["coming", 'coming']], selected)
 	end

 	def leaves_reason_options_for_select(selected)
 		options = LeavesHolidaysLogic.issues_list.pluck(:subject, :id)
	    options_for_select(options, selected)
 	end

end
