class LeaveTimelinesController < ApplicationController
  unloadable

  menu_item :redmine_leaves_holidays
  include LeavesHolidaysLogic

  helper :leave_requests
  include LeaveRequestsHelper
  helper :leave_timelines
  
  before_action :set_user
  before_action :find_project, only: [:show_project]
  before_action :check_clear_filters

  def show
    @timeline = RedmineLeavesHolidays::Helpers::Timeline.new(params)

    user_projects = @user.memberships.pluck(:project_id)

    @projects = Project.where(id: user_projects)
    if params[:projects].present?
      @projects = Project.where(id: params[:projects])
      session[:timeline_projects_filters] = params[:projects]
    else
      @projects = Project.where(id: session[:timeline_projects_filters]) if session[:timeline_projects_filters].present?
    end

    projects_members = Member.includes(:project, :user).where(users: {status: 1}, project_id: @projects.pluck(:id)).pluck(:user_id).uniq
    
    @scope_initial = leave_requests_initial_users(projects_members)

    set_region_filter


    @roles = roles_list.to_a.sort
    if params[:roles].present?
      roles = roles_list.where(id: params[:roles])
      session[:timeline_role_filters] = params[:roles]
    else
      roles = roles_list.where(id: session[:timeline_role_filters]) if session[:timeline_role_filters].present?
    end
    @role_ids = roles.pluck(:id)
    @timeline.role_ids = @role_ids



    scope = @scope_initial.where(region: @region)
    

    @timeline.user = @user
    @timeline.projects = @projects.to_a
    @timeline.leave_list = scope

    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
    end
  end

  def show_project
    @timeline = RedmineLeavesHolidays::Helpers::Timeline.new(params)
    @timeline.user = @user
    user_ids = @project.members.pluck(:user_id)
    @timeline.project = @project

    @scope_initial = leave_requests_initial_users(user_ids)

    set_region_filter

    roles = Role.all.givable#Role.where(id: LeavesHolidaysLogic.roles_for_project(@project).map(&:id))
    @roles = roles.to_a.sort
    if params[:roles].present?
      roles = roles.where(id: params[:roles])
      session[:timeline_role_project_filters] = params[:roles]
    else
      roles = roles.where(id: session[:timeline_role_project_filters]) if session[:timeline_role_project_filters].present?
    end
    @role_ids = roles.pluck(:id)
    @timeline.role_ids = @role_ids


    @timeline.role_ids = @role_ids
    
    scope = @scope_initial.where(region: @region)

    @timeline.leave_list = scope

  
    respond_to do |format|
      format.html { render :action => "show_project", :layout => !request.xhr? }
    end
  end

  private

  def set_user
    @user ||= User.current
  end

  def find_project
    @project = Project.find(params[:project_id])
    render_403 if  !@project.module_enabled?(:leave_timeline_view) || !LeavesHolidaysLogic.has_create_rights(@user)
  end

  def leave_requests_initial_users(user_ids)
    uid = @user.id
    leave_requests = LeaveRequest.overlaps(@timeline.date_from, @timeline.date_to).where(user_id: user_ids.uniq).includes(:leave_status).to_a
    leave_requests.delete_if{|l| (l.user_id != uid && l.get_status.in?(["created", "rejected"])) || (l.user_id == uid && l.get_status == "rejected") }
    LeaveRequest.where(id: leave_requests.map(&:id))
  end

  def set_region_filter
    @region = @scope_initial.group('region').count.to_hash.keys
    if params[:region].present?
      @region = params[:region]
      session[:timeline_region_filters] = params[:region]
    else
      @region = session[:timeline_region_filters] if session[:timeline_region_filters].present?
    end
  end

  def check_clear_filters
    if params[:clear_filters].present?
      session.delete(:timeline_projects_filters) if session[:timeline_projects_filters]
      session.delete(:timeline_region_filters) if session[:timeline_region_filters]
      params.delete :clear_filters
    end
  end

  def roles_list
    # projects = @projects || [@project]
    # role_ids = []
    # projects.each do |project|
    #   role_ids << LeavesHolidaysLogic.roles_for_project(project).map(&:id)
    # end
    role_ids = Role.all.givable.to_a#.delete_if {|r| !:create_leave_requests.in?(r[:permissions])}
    return Role.where(id: role_ids)
  end



end