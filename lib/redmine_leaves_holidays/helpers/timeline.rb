module RedmineLeavesHolidays
  module Helpers
    class Timeline
      class MaxLinesLimitReached < Exception
      end

      include ERB::Util
      include Redmine::I18n
      include Redmine::Utils::DateCalculation
      include LeaveTimelinesHelper

      attr_reader :year_from, :month_from, :date_from, :date_to, :zoom, :months, :truncated, :max_rows

      attr_accessor :view
      attr_accessor :leave_list
      attr_accessor :project
      attr_accessor :projects
      attr_accessor :user
      attr_accessor :role_ids

      def initialize(options={})
        options = options.dup
        if options[:year] && options[:year].to_i >0
          @year_from = options[:year].to_i
          if options[:month] && options[:month].to_i >=1 && options[:month].to_i <= 12
            @month_from = options[:month].to_i
          else
            @month_from = 1
          end
        else
          @month_from ||= Date.today.month
          @year_from ||= Date.today.year
        end
        zoom = (options[:zoom] || User.current.pref[:timeline_zoom]).to_i
        @zoom = (zoom > 0 && zoom < 6) ? zoom : 5
        months = (options[:months] || User.current.pref[:timeline_months]).to_i
        @months = (months > 0 && months < 25) ? months : 1

        if (User.current.logged? && (@zoom != User.current.pref[:timeline_zoom] ||
              @months != User.current.pref[:timeline_months]))
          User.current.pref[:timeline_zoom], User.current.pref[:timeline_months] = @zoom, @months
          User.current.preference.save
        end
        @date_from = Date.civil(@year_from, @month_from, 1)
        @date_to = (@date_from >> @months) - 1
        @users = ''
        @lines = ''
        @number_of_rows = nil
        @truncated = false
        if options.has_key?(:max_rows)
          @max_rows = options[:max_rows]
        else
          @max_rows = 1000
        end
      end

      def common_params
        p = { :controller => 'leave_timelines', :action => 'show' }
        if @project
         # p.merge({:project_id => @project.id})
          p[:action] = 'show_project'
        end
        return p
      end

      def params
        common_params.merge({:zoom => zoom, :year => year_from,
                             :month => month_from, :months => months})
      end

      def params_previous
        common_params.merge({:year => (date_from << months).year,
                             :month => (date_from << months).month,
                             :zoom => zoom, :months => months})
      end

      def params_next
        common_params.merge({:year => (date_from >> months).year,
                             :month => (date_from >> months).month,
                             :zoom => zoom, :months => months})
      end

      def render(options={})
        options = {:top => 0, :top_increment => 20,
                   :indent_increment => 20, :render => :subject,
                   :format => :html}.merge(options)
        indent = options[:indent] || 4
        @users = '' unless options[:only] == :lines
        @lines = '' unless options[:only] == :users
        @number_of_rows = 0
        begin
          if @project
            options[:indent] = indent
            render_project(@project, options)
          else
            projects_list_tree.each do |project_tree|
              project = project_tree[0]
              options[:indent] = indent + project_tree[1] * 10
              render_project(project, options)
            end
          end
        rescue MaxLinesLimitReached
          @truncated = true
        end
        @users_rendered = true unless options[:only] == :lines
        @lines_rendered = true unless options[:only] == :users
      end

      def number_of_rows
        return @number_of_rows if @number_of_rows
        return @leave_list.distinct.pluck(:user_id)
      end

      def users_list
        return @leave_list.includes(:user).map(&:user).uniq
      end

      def projects_list_tree
        if @projects
          # return @user.leave_memberships.map {|m| m.project}
          #projects_user = @user.memberships.map {|m| m.project}
          plist = []
          Project.project_tree(projects) do |p, l|
            plist << [p, l]
          end
          return plist
        else
          return []
        end
      end

      def members_list(project)
        return [] unless project
        user_ids = users_list.map(&:id)
        return project.members.where(user_id: user_ids).includes(:roles).to_a.uniq
      end

      # Returns [[Role 1,[User 1, User 2...]],...]
      # if role_ids
      def roles_users_list(project)
        return [] unless project
        roles_users = project.users_by_role.sort.map {|t| [t[0], t[1].sort{|a,b| a.login <=> b.login}] }
        if @role_ids && !@role_ids.empty?
          return roles_users.delete_if{|t| !t[0].id.in?(@role_ids)}
        else
          return roles_users
        end
      end

      def leave_list_for_user(user)
        return @leave_list.where(user_id: user.id).to_a
      end

      def users(options={})
        render(options.merge(:only => :users)) unless @users_rendered
        @users
      end

      def lines(options={})
        render(options.merge(:only => :lines)) unless @lines_rendered
        @lines
      end

      def render_project(project, options={})
        # Get project members
        members = members_list(project)
          # If there are members to display
          unless members.empty?
            # Render project name
            render_object_row(project, options)
            # Indent
            increment_indent(options)

            # Get roles associated with project, and loop for each of them
            roles_users_list(project).each do |role_users|
              
              # Check if leave requests are qssociated to the role
              leave_count_role = role_users[1].map{|user| @leave_list.where(user_id: user.id).count }

              # If there are leave requests to show
              if leave_count_role.inject(:+) > 0
                # Render role name
                render_object_row(role_users[0], options)
                # Indent
                increment_indent(options)

                # Get users associated with the role and loop
                role_users[1].each_with_index do |user, i|
                  # If given user has at least a leave request
                  if leave_count_role[i] > 0
                    # render his leave
                    render_user(user, options)
                  end
                end
                decrement_indent(options)
            end
          end

          decrement_indent(options)
        end
      end

      def render_role(role, options={})

      end

      def render_user(user, options={})
        render_object_row(user, options)
      end

      def render_object_row(object, options)
        class_name = object.class.name.downcase
        send("subject_for_#{class_name}", object, options) unless options[:only] == :lines
        send("line_for_#{class_name}", object, options) unless options[:only] == :subjects
        options[:top] += options[:top_increment]
        @number_of_rows += 1
        if @max_rows && @number_of_rows >= @max_rows
          raise MaxLinesLimitReached
        end
      end

      def subject_for_user(user, options)
        subject(user.name, options, user)
      end

      def line_for_user(user, options)
        leave_list_for_user(user).each do |leave|
          label = ''
          line(leave.from_date, leave.to_date, false, label, options, leave)
        end
      end

      def subject_for_project(project, options)
        subject(project.name, options, project)
      end

      def line_for_project(project, options)
      end

      def subject_for_role(role, options)
        subject(role.name, options, role)
      end

      def line_for_role(role, options)
      end

      def line(start_date, end_date, markers, label, options, object=nil)
        options[:zoom] ||= 1
        options[:g_width] ||= (self.date_to - self.date_from + 1) * options[:zoom]
        if object.half_day?
          if object.has_am?
            coords = coordinates(start_date, end_date, options[:zoom], true)
          else
            coords = coordinates(start_date, end_date, options[:zoom], false, true)
          end
        else
          coords = coordinates(start_date, end_date, options[:zoom])
        end
        html_task(options, coords, markers, label, object)
      end

      def subject(label, options, object=nil)
        html_subject(options, label, object)
      end

      def countries
        user_ids = @leave_list.distinct.pluck(:user_id)
        LeavePreference.where(user_id: user_ids).distinct.pluck(:region)
      end

      # Optimise for date_from - date_to period
      def holiday_date(date)
        countries.map {|c| date.holiday?(c.to_sym, :observed)}.any?
      end

      def country_holiday_list(date)
        countries.delete_if {|c| !date.holiday?(c.to_sym, :observed)}
      end

      def increment_indent(options, factor=1)
        options[:indent] += options[:indent_increment] * factor
        if block_given?
          yield
          decrement_indent(options, factor)
        end
      end

      def decrement_indent(options, factor=1)
        increment_indent(options, -factor)
      end

    private

      def coordinates(start_date, end_date, zoom=nil, is_am=false, is_pm=false)
        zoom ||= @zoom
        coords = {}
        if start_date && end_date && start_date <= self.date_to && end_date >= self.date_from
          if start_date >= self.date_from
            coords[:start] = start_date - self.date_from
            coords[:bar_start] = start_date - self.date_from
            coords[:bar_start] = start_date - self.date_from + 0.5 if is_pm
          else
            coords[:bar_start] = 0
          end
          if end_date <= self.date_to
            coords[:end] = end_date - self.date_from
            coords[:bar_end] = end_date - self.date_from + 1
            coords[:bar_end] = end_date - self.date_from + 0.5 if is_am
          else
            coords[:bar_end] = self.date_to - self.date_from + 1
          end
        end
        # Transforms dates into pixels witdh
        coords.keys.each do |key|
          coords[key] = (coords[key] * zoom).floor
        end
        coords
      end

      def html_subject_content(object)
        user = object
        css_classes = ''
        css_classes << ' icon'

        s = "".html_safe

        s << view.avatar(user,
                        :size => 10,
                        :title => '').to_s.html_safe
        s << " ".html_safe
        s << view.link_to_user(user).html_safe
        view.content_tag(:span, s, :class => css_classes).html_safe
      end

      def html_subject(params, subject, object)
        style = "position: absolute;top:#{params[:top]}px;left:#{params[:indent]}px;"
        style << "width:#{params[:subject_width] - params[:indent]}px;" if params[:subject_width]
        content = html_subject_content(object) || subject
        tag_options = {:style => style}
        case object
        when User
        tag_options[:id] = "issue-#{object.id}"
        tag_options[:class] = "issue-subject"
        tag_options[:title] = object.name
        when Project
          tag_options[:class] = "project-name"
        when Role
          tag_options[:class] = "project-name"
        end 

        output = view.content_tag(:div, content, tag_options)
        @users << output
        output
      end

      def html_task(params, coords, markers, label, object)
        output = ''

        css = "task parent"

        # Renders the task bar, with progress and late
        if coords[:bar_start] && coords[:bar_end]
          width = coords[:bar_end] - coords[:bar_start] - 2
          style = ""
          style << "top:#{params[:top]}px;"
          style << "left:#{coords[:bar_start]}px;"
          style << "width:#{width}px;"
          style << "height:10px;"
          style << object.css_style
          if object.get_status != "accepted"
            style << "background: repeating-linear-gradient(45deg, #606dbc, #606dbc 10px, #465298 10px, #465298 30px);"
            style << "filter: progid:DXImageTransform.Microsoft.Gradient(startColorstr='#606dbc', endColorstr='#460000');"
          end
          html_id = "task-todo-issue-#{object.id}"
          content_opt = {:style => style,
                         :class => "#{css} task_todo",
                         :id => html_id}

          output << view.content_tag(:div, '&nbsp;'.html_safe, content_opt)

        end
        # Renders the markers
        if markers
          if coords[:start]
            style = ""
            style << "top:#{params[:top]}px;"
            style << "left:#{coords[:start]}px;"
            style << "width:15px;"
            output << view.content_tag(:div, '&nbsp;'.html_safe,
                                       :style => style,
                                       :class => "#{css} marker starting")
          end
          if coords[:end]
            style = ""
            style << "top:#{params[:top]}px;"
            style << "left:#{coords[:end] + params[:zoom]}px;"
            style << "width:15px;"
            output << view.content_tag(:div, '&nbsp;'.html_safe,
                                       :style => style,
                                       :class => "#{css} marker ending")
          end
        end
        # Renders the label on the right
        if label
          style = ""
          style << "top:#{params[:top]}px;"
          style << "left:#{(coords[:bar_end] || 0) + 8}px;"
          style << "width:15px;"
          output << view.content_tag(:div, label,
                                     :style => style,
                                     :class => "#{css} label")
        end
        #Renders the tooltip
        if coords[:bar_start] && coords[:bar_end]
          s = view.content_tag(:span,
                               view.render_leave_tooltip(object).html_safe,
                               :class => "ltip")
          style = ""
          style << "position: absolute;"
          style << "top:#{params[:top]}px;"
          style << "left:#{coords[:bar_start]}px;"
          style << "width:#{coords[:bar_end] - coords[:bar_start]}px;"
          style << "height:12px;"
          output << view.content_tag(:div, s.html_safe,
                                     :style => style,
                                     :class => "ltooltip")
        end
        @lines << output
        output
      end

    end
  end
end