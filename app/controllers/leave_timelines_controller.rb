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
    @timeline.user = @user
    

    @projects_initial = LeavesHolidaysLogic.system_leave_projects & @user.projects

    @leave_requests_initial = LeaveRequest.viewable_by(@user.id).not_rejected
    @regions_initial = @leave_requests_initial.group('region').distinct.count.keys.sort

    @roles_initial = @projects_initial.map{|p| p.role_list}.flatten.uniq
    @users_initial = LeavesHolidaysLogic.users_for_projects(@projects_initial)

    @region_selected = params[:region] if params[:region].present?

    @roles_selected = params[:roles] if params[:roles].present?
    roles = Role.where(id: @roles_selected) if @roles_selected
    @timeline.roles = roles || @roles_initial

    #@projects_selected = params[:projects].map(&:to_i) if params[:projects].present?
    @projects_selected = @projects_initial.select{|p| p.id.in?(params[:projects].map(&:to_i))} if params[:projects].present?




    # @projects_selected = params[:projects] if params[:projects].present?

    # @timeline.projects = @projects_initial
    # @timeline.projects = @projects_initial.select{|p| p.id.in?(@projects_selected.map(&:to_i))} if @projects_selected



    @timeline.projects = @projects_initial.to_a
    @timeline.projects = @projects_selected if @projects_selected


    @users_selected = @users_initial
    @users_selected = @users_initial.like(params[:name]) if params[:name].present?
    @users_selected = @users_selected.with_leave_region(@region_selected) if @region_selected
    @users_selected = LeavesHolidaysLogic.users_with_roles_for_projects(roles, @timeline.projects) & @users_selected if roles
    @timeline.users = @users_selected.to_a

    # @projects = @user.leave_projects
    # if params[:projects].present?
    #   @projects = Project.where(id: params[:projects])
    #   @user.pref[:timeline_projects_filters] = params[:projects]
    #   @user.preference.save
    # else
    #   @projects = Project.where(id: @user.pref[:timeline_projects_filters]) if @user.pref[:timeline_projects_filters].present?
    # end

    # projects_user_ids = Member.includes(:project, :user).where(users: {status: 1}, project_id: @projects.pluck(:id)).pluck(:user_id).uniq
    
    # users = User.where(id: projects_user_ids)

    # users = users.like(params[:name]) if params[:name].present?

    # @users_initial =  users.order(:firstname).map {|u| [u.name, u.id]}
    
    # @user_ids = users.order(:firstname).pluck(:id)

    # @scope_initial = leave_requests_initial_users(@user_ids)

    # set_region_filter

    # roles = Role.all.givable
    # @roles = roles.to_a.sort
    # if params[:roles].present?
    #   roles = role_list.where(id: params[:roles])
    #   @user.pref[:timeline_role_filters] = params[:roles]
    #   @user.preference.save
    # else
    #   roles = role_list.where(id: @user.pref[:timeline_role_filters]) if @user.pref[:timeline_role_filters].present?
    # end
    # @role_ids = roles.pluck(:id)
    # @timeline.role_ids = @role_ids



    # scope = @scope_initial.where(region: @region)
    

    


    @timeline.show_roles = true if params[:show_roles]
    @timeline.show_projects = true if params[:show_projects]

    @timeline.leave_list = @leave_requests_initial
    
    @timeline.leave_list = @leave_requests_initial.where(user: @users_initial.like(params[:name])) if params[:name].present?

    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
    end
  end

  def show_project
    @timeline = RedmineLeavesHolidays::Helpers::Timeline.new(params)

    @timeline.user = @user
    @timeline.project = @project

    @projects_initial = [@project]
    @users_initial = @project.users
    @leave_requests_initial = leave_requests_initial_users(@users_initial.map(&:id))
    @regions_initial = @leave_requests_initial.group('region').distinct.count.keys.sort
    @roles_initial = @project.role_list
    
    @region_selected = params[:region] if params[:region].present?
    @roles_selected = params[:roles] if params[:roles].present?
    roles = Role.where(id: @roles_selected) if @roles_selected
    @timeline.roles = roles || @roles_initial

    @projects_selected = nil
    @projects_selected = @projects_initial.select{|p| p.id.in?(params[:projects].map(&:to_i))} if params[:projects].present?

    @timeline.projects = @projects_initial.to_a

    @users_selected = @users_initial
    @users_selected = @users_initial.like(params[:name]) if params[:name].present?
    @users_selected = @users_selected.with_leave_region(@region_selected) if @region_selected
    @users_selected = LeavesHolidaysLogic.users_with_roles_for_projects(roles, @timeline.projects) & @users_selected if roles
    @timeline.users = @users_selected.to_a

    # user_ids = @project.members.pluck(:user_id)
    # users = User.where(id: user_ids)

    # @users_initial =  users.order(:firstname).map {|u| [u.name, u.id]}
    # @user_ids = params[:users] || users.order(:firstname).pluck(:id)

    # @timeline.project = @project

    # @scope_initial = leave_requests_initial_users(@user_ids)

    # set_region_filter

    # roles = Role.all.givable#Role.where(id: LeavesHolidaysLogic.roles_for_project(@project).map(&:id))
    # @roles = roles.to_a.sort
    # if params[:roles].present?
    #   roles = roles.where(id: params[:roles])
    #   @user.pref[:timeline_role_project_filters] = params[:roles]
    #   @user.preference.save
    # else
    #   roles = roles.where(id: @user.pref[:timeline_role_project_filters]) if @user.pref[:timeline_role_project_filters].present?
    # end
    # @role_ids = roles.pluck(:id)
    # @timeline.role_ids = @role_ids


    # @timeline.role_ids = @role_ids
    
    # scope = @scope_initial.where(region: @region)

    # @timeline.leave_list = scope

    @timeline.show_roles = true if params[:show_roles]
    @timeline.show_projects = true

    @timeline.leave_list = @leave_requests_initial
    @timeline.leave_list = @leave_requests_initial.where(user: @users_initial.like(params[:name])) if params[:name].present?

  
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
    render_403 if  !@project.module_enabled?(:leave_management) || !LeavesHolidaysLogic.has_create_rights(@user)
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
      @user.pref[:timeline_region_filters] = params[:region]
      @user.preference.save
    else
      @region = @user.pref[:timeline_region_filters] if @user.pref[:timeline_region_filters].present?
    end
  end

  def check_clear_filters
    if params[:clear_filters].present?
      @user.pref[:timeline_projects_filters] = nil
      @user.pref[:timeline_region_filters] = nil
      @user.pref[:timeline_role_project_filters] = nil
      @user.pref[:timeline_role_filter] = nil
      @user.preference.save
      params.delete :clear_filters
    end
  end

  def role_list
    # projects = @projects || [@project]
    # role_ids = []
    # projects.each do |project|
    #   role_ids << LeavesHolidaysLogic.roles_for_project(project).map(&:id)
    # end
    role_ids = Role.all.givable.to_a#.delete_if {|r| !:create_leave_requests.in?(r[:permissions])}
    return Role.where(id: role_ids)
  end



end