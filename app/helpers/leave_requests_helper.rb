module LeaveRequestsHelper
	include LeavesHolidaysLogic
	include LeavesHolidaysPermissions

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

		can_create_leave_requests = authenticate_leave_request({action: :index})

		if can_create_leave_requests
			tabs << {:label => :tab_my_leaves, :controller => 'leave_requests', :action => 'index'}
		end

		if  authenticate_leave_status({action: :index})
			tabs << { :label => :tab_leaves_approval, :controller => 'leave_approvals', :action => 'index'}
		end

		if can_create_leave_requests
			tabs << {:label => :tab_leaves_timeline, :controller => 'leave_timelines', :action => 'show'}
		end


		if authenticate_leave_preferences({action: :index})
			tabs << { :label => :tab_user_leaves_preferences, :controller => 'leave_preferences', :action => 'index'}
		end

		return tabs
	end

	def leaves_status_options_for_select(status_count, selected)
		options_for_select([["submitted (#{status_count[1].to_i})".html_safe, '1'],
	                        ["processing (#{status_count[4].to_i})".html_safe, '4'],
	                        ["processed (#{status_count[2].to_i})".html_safe, '2']], selected)
 	end

 	def leaves_status_options_for_select_count(selected)
 		submitted_count = @scope_initial.submitted_or_processing.count
 		processed_count = @scope_initial.processed.count

 		options = []
 		options << ["Submitted (#{submitted_count})".html_safe, 'submitted_or_processing']
 		options << ["Processed (#{processed_count})".html_safe, 'processed']

 		options_for_select(options, selected)
 	end

 	def leaves_regions_options_for_select(selected)
	    options_for_select(@regions_initial, selected)
 	end 	

 	def leaves_regions_options_for_select_count(selected)
 			options = @scope_initial.group('region').count.to_hash.collect {|k, v| ["#{k} (#{v})".html_safe, k]}
	    options_for_select(options, selected)
 	end

 	def leaves_dates_options_for_select(selected)
 			hsh = { finished: 'Past', ongoing: 'Present', coming: 'Future'}
 			options = []
 			hsh.each do |k,v|
 				option = []
 				count = 0
 				count = @scope_initial.when(k.to_s).count
 				options << ["#{v} (#{count})".html_safe, k.to_s]
 			end
	    options_for_select(options, selected)
 	end

 	def leaves_reason_options_for_select(selected)
 		options = @scope_initial.group('issue').count.to_hash.collect {|k, v| ["#{k.subject} (#{v})".html_safe, k.id]}.sort
	    options_for_select(options, selected)
 	end

 	def leaves_users_options_for_select(selected)
 		users_leave_count = @scope_initial.group(:user_id).count

 		options = @users_initial_viewable.sort_by(&:name).map {|u| count = users_leave_count[u.id] || 0;
 			["#{u.name} (#{count})", u.id]}

 		options_for_select(options, selected)
 	end

 	def user_projects(user)
 		#leave_managed_projects = user.leave_managed_projects.map(&:id)
 		projects = user.memberships.collect{ |e| e.project }.uniq

	 	s = ''.html_safe

	    project_tree(projects) do |project, level|
	      if level == 0
		      check_img = "".html_safe
		      #check_img = " ".html_safe + checked_image.html_safe if project.id.in?(leave_managed_projects)
		      # s << content_tag('p', h(project) + check_img)
		      if project.visible?
		      	s << content_tag('p', link_to(project.name, project))
		      else
		      	s << content_tag('p', project)
		      end
		      
		  end
	    end
	    s.html_safe
 	end

 	def leave_period(user)
 		period = user.leave_period
 		output = "".html_safe
 		output << "From: #{format_date(period[:start])}<br/>".html_safe
 		output << "To: #{format_date(period[:end])}<br/>".html_safe
 	end

 	def leave_roles_options_for_select(selected)
    options = @roles_initial.sort_by(&:name).map{|k| [k.name, k.id]}
    options_for_select(options, selected)
  end

 	def users_link_to_notification(users)
 		users.map{|user| link_to user.name, notification_user_leave_preference_path(user)}.join(', ').html_safe
 	end

 	def user_link_to_checked_if_managed_in_project(user, project)
 		str = "".html_safe
 		str += user.name.html_safe

 		if user.is_system_leave_admin?
 			str += ' '.html_safe + image_tag('group.png').html_safe
 		elsif user.is_project_leave_admin?(project)
 			str += ' '.html_safe + image_tag('user.png').html_safe
 			if user.is_rule_managed?
 				str += ' '.html_safe + image_tag('toggle_check_amber.png', :plugin => 'redmine_leaves_holidays').html_safe
 			end
 		elsif user.is_contractor
 			str += ' '.html_safe + image_tag('hourglass.png', :size => '12x12').html_safe
 			unless user.is_rule_notifying?
 				str += ' '.html_safe + image_tag('false.png', :size => '12x12').html_safe
 			end
 		elsif user.is_rule_managed_in_project?(project)
 			str +=  ' '.html_safe + checked_image.html_safe
 		elsif user.is_rule_managed?
 			str += ' '.html_safe + image_tag('toggle_check_amber.png', :plugin => 'redmine_leaves_holidays').html_safe
 		else
 			if user.is_managing?(false)
 				str += ' '.html_safe + image_tag('reload.png').html_safe
 			else
 				str += ' '.html_safe + image_tag('false.png', :size => '12x12').html_safe
 			end
 			
 		end

 		link_to str, notification_user_leave_preference_path(user)
 	end

 	def users_link_to_checked_if_managed_in_project(users, project)
 		users.map{|user| user_link_to_checked_if_managed_in_project(user, project)}.join(', ').html_safe
 	end

 	def human_boolean(boolean)
    boolean ? 'Yes' : 'No'
	end

	def leave_projects_options_for_select(selected)
    project_tree_options_for_select(@projects_initial, :selected => selected)
  end

end