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
  before_action :check_is_apply_form
  before_action :authenticate, only: [:show]
  before_action :set_viewable_users_leave

  def show
    @timeline = RedmineLeavesHolidays::Helpers::Timeline.new(params)
    @timeline.user = @user
    

    @projects_initial = LeavesHolidaysLogic.system_leave_projects & @user.projects
    @users_initial = LeavesHolidaysLogic.users_for_projects(@projects_initial)
    @leave_requests_initial = leave_requests_initial_users(@users_initial.map(&:id))

    @roles_initial = @projects_initial.map{|p| p.role_list}.flatten.uniq
    @regions_initial = (@users_initial.joins(:leave_preference).group("leave_preferences.region").count.to_hash.keys + [RedmineLeavesHolidays::Setting.defaults_settings(:region)]).uniq


    fetch_regions
    fetch_roles

    @timeline.regions = @regions_initial
    @timeline.regions = @regions_selected if @regions_selected

    roles = Role.where(id: @roles_selected) if @roles_selected
    @timeline.roles = roles || @roles_initial

    if params[:projects].present?
      @projects_selected = @projects_initial.select{|p| p.id.in?(params[:projects].map(&:to_i))}
      @user.pref[:leave_timeline_filters_projects] = params[:projects]
      @user.preference.save
    else
      @projects_selected = @projects_initial.select{|p| p.id.in?(@user.pref[:leave_timeline_filters_projects].map(&:to_i))} if @user.pref[:leave_timeline_filters_projects].present?
    end

    @timeline.projects = @projects_initial.to_a
    @timeline.projects = @projects_selected if @projects_selected


    @users_selected = @users_initial
    @users_selected = @users_initial.like(params[:name]) if params[:name].present?
    @users_selected = @users_selected.with_leave_region(@regions_selected) if @regions_selected
    @users_selected = LeavesHolidaysLogic.users_with_roles_for_projects(roles, @timeline.projects) & @users_selected if roles
    @timeline.users = @users_selected.to_a

    fetch_show_roles
    fetch_show_projects


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
    
    fetch_regions
    fetch_roles

    @timeline.regions = @regions_initial
    @timeline.regions = @regions_selected if @regions_selected

    roles = Role.where(id: @roles_selected) if @roles_selected
    @timeline.roles = roles || @roles_initial

    @projects_selected = nil
    @projects_selected = @projects_initial.select{|p| p.id.in?(params[:projects].map(&:to_i))} if params[:projects].present?

    @timeline.projects = @projects_initial.to_a

    @users_selected = @users_initial
    @users_selected = @users_initial.like(params[:name]) if params[:name].present?
    @users_selected = @users_selected.with_leave_region(@regions_selected) if @regions_selected
    @users_selected = LeavesHolidaysLogic.users_with_roles_for_projects(roles, @timeline.projects) & @users_selected if roles
    @timeline.users = @users_selected.to_a

    fetch_show_roles
    @timeline.show_projects = true

    @timeline.leave_list = @leave_requests_initial
    @timeline.leave_list = @leave_requests_initial.where(user: @users_initial.like(params[:name])) if params[:name].present?

  
    respond_to do |format|
      format.html { render :action => "show_project", :layout => !request.xhr? }
    end
  end

  private

  def set_viewable_users_leave
    @viewable_users = @user.viewable_user_list
  end

  def set_user
    @user = User.current
  end

  def find_project
    @project = Project.find(params[:project_id])
    render_403 if  !@project.module_enabled?(:leave_management) || !@user.can_create_leave_requests
  end

  def leave_requests_initial_users(user_ids)
    uid = @user.id
    leave_requests = LeaveRequest.overlaps(@timeline.date_from, @timeline.date_to).where(user_id: user_ids.uniq).includes(:leave_status).to_a
    leave_requests.delete_if{|l| (l.user_id != uid && l.get_status.in?(["created", "rejected"])) || (l.user_id == uid && l.get_status == "rejected") }
    LeaveRequest.where(id: leave_requests.map(&:id))
  end

  def remove_filters
    @user.pref[:leave_timeline_filters_regions] = nil
    @user.pref[:leave_timeline_filters_roles] = nil
    @user.pref[:leave_timeline_filters_projects] = nil
    @user.pref[:leave_timeline_filters_roles] = nil
    @user.pref[:leave_timeline_filters_show_roles] = nil
    @user.pref[:leave_timeline_filters_show_projects] = nil

    @user.preference.save
  end

  def check_clear_filters
    if params[:clear_filters].present?
      remove_filters
      params.delete :clear_filters
    end
  end

  def check_is_apply_form
    if params[:apply_form] && params[:apply_form] == "1"
      @is_apply = true
      remove_filters
    end
  end

  def fetch_regions
    if params[:region].present?
      @regions_selected = params[:region]
      @user.pref[:leave_timeline_filters_regions] = params[:region]
      @user.preference.save
    else
      @regions_selected = @user.pref[:leave_timeline_filters_regions] if @user.pref[:leave_timeline_filters_regions].present?
    end
  end

  def fetch_roles
    if params[:roles].present?
      @roles_selected = params[:roles]
      @user.pref[:leave_timeline_filters_roles] = params[:roles]
      @user.preference.save
    else
      @roles_selected = @user.pref[:leave_timeline_filters_roles] if @user.pref[:leave_timeline_filters_roles].present?
    end
  end

  def fetch_show_roles
    if @is_apply
      @timeline.show_roles = true if params[:show_roles].present?
      @user.pref[:leave_timeline_filters_show_roles] = @timeline.show_roles
      @user.preference.save
    else
      @timeline.show_roles = @user.pref[:leave_timeline_filters_show_roles] if @user.pref[:leave_timeline_filters_show_roles]
      params[:show_roles] = true if @timeline.show_roles
    end
  end

  def fetch_show_projects
    if @is_apply
      @timeline.show_projects = true if params[:show_projects].present?
      @user.pref[:leave_timeline_filters_show_projects] = @timeline.show_projects
      @user.preference.save
    else
      @timeline.show_projects = @user.pref[:leave_timeline_filters_show_projects] if @user.pref[:leave_timeline_filters_show_projects]
      params[:show_projects] = true if @timeline.show_projects
    end
  end

  def role_list
    role_ids = Role.all.givable.to_a
    return Role.where(id: role_ids)
  end

  def authenticate
    render_403 unless @user.has_leave_plugin_access?
  end



end