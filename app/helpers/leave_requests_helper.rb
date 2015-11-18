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

		if LeavesHolidaysLogic::has_create_rights(@user)
			tabs << {:label => :tab_my_leaves, :controller => 'leave_requests', :action => 'index'}
		end

		if LeavesHolidaysLogic::user_has_any_manage_right(@user) || LeavesHolidaysLogic::has_view_all_rights(@user)
			tabs << { :label => :tab_leaves_approval, :controller => 'leave_approvals', :action => 'index'}
		end

		tabs << {:label => :tab_leaves_timeline, :controller => 'leave_timelines', :action => 'show'}

		if LeavesHolidaysLogic::has_manage_user_leave_preferences(@user)
			tabs << { :label => :tab_user_leaves_preferences, :controller => 'leave_preferences', :action => 'index'}
		end

		return tabs
	end

	def leaves_status_options_for_select(status_count, selected)
		options_for_select([["submitted (#{status_count[1].to_i})".html_safe, '1'],
	                        ["processing (#{status_count[4].to_i})".html_safe, '4'],
	                        ["processed (#{status_count[2].to_i})".html_safe, '2']], selected)
 	end

 	def leaves_regions_options_for_select(selected, show_count=true)
 		if show_count
 			options = @scope_initial.group('region').count.to_hash.map {|k, v| ["#{k} (#{v})".html_safe, k]}.sort
 		else
 			options = @scope_initial.group('region').count.to_hash.map {|k, v| ["#{k}".html_safe, k]}.sort
 		end
	    options_for_select(options, selected)
 	end

 	def leaves_dates_options_for_select(selected)
	    options_for_select([['Past', 'finished'],
	                        ['Present', 'ongoing'],
	                        ['Future', 'coming']], selected)
 	end

 	def leaves_reason_options_for_select(selected)
 		options = @scope_initial.group('issue').count.to_hash.collect {|k, v| ["#{k.subject} (#{v})".html_safe, k.id]}.sort
	    options_for_select(options, selected)
 	end

 	def leaves_users_options_for_select(selected)
 		options = @scope_initial.group('user').count.to_hash.collect {|k, v| ["#{k.name} (#{v})".html_safe, k.id]}.sort
 		options_for_select(options, selected)
 	end

 	def user_projects(user)
 		leave_managed_projects = user.leave_managed_projects.map(&:id)
 		projects = user.memberships.collect{ |e| e.project }.uniq

	 	s = ''.html_safe

	    project_tree(projects) do |project, level|
	      if level == 0
		      check_img = "".html_safe
		      check_img = " ".html_safe + checked_image.html_safe if project.id.in?(leave_managed_projects)
		      s << content_tag('p', h(project) + check_img)
		  end
	    end
	    s.html_safe
 	end

 	def leave_projects_options_for_select(selected)
 		projects = Project.all.active
 		project_tree_options_for_select(projects, :selected => selected)
 	end

 	def leave_period(user)
 		period = user.leave_period
 		output = "".html_safe
 		output << "From: #{format_date(period[:start])}<br/>".html_safe
 		output << "To: #{format_date(period[:end])}<br/>".html_safe
 	end

 	def months_options_for_select(selected)
 		options = Date::MONTHNAMES[1..-1].map.with_index(1).to_a
 		options_for_select(options, selected)
 	end

 	def years_options_for_select(selected)
 		year = Date.today.year
 		options = [*(year-5)..(year+5)].map{|k| [k.to_s.html_safe,k]}
 		options_for_select(options, selected)
 	end

 	def roles_options_for_select(selected)
 		options = Role.all.givable.map{|k| [k.name, k.id]}
 		options_for_select(options, selected)
 	end

	def users_regions_options_for_select(selected, show_count=true)
 		if show_count
 			options = @scope_initial.group('region').count.to_hash.map {|k, v| ["#{k} (#{v})".html_safe, k]}.sort
 		else
 			options = @scope_initial.group('region').count.to_hash.map {|k, v| ["#{k}".html_safe, k]}.sort
 		end
	    options_for_select(options, selected)
 	end

 	def users_link_to_notification(users)
 		users.map{|user| link_to user.name, notification_user_leave_preference_path(user)}.join(', ').html_safe
 	end

end