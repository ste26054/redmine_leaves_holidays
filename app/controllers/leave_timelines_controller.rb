class LeaveTimelinesController < ApplicationController
  unloadable

  menu_item :redmine_leaves_holidays
  include LeavesHolidaysLogic

  helper :leave_requests
  include LeaveRequestsHelper
  helper :leave_timelines
  
  before_action :set_user
  before_action :find_project, only: [:show_project]

  def show
    @timeline = RedmineLeavesHolidays::Helpers::Timeline.new(params)

    user_projects = @user.leave_memberships.pluck(:project_id)
    projects_members = Member.includes(:project, :user).where(users: {status: 1}, project_id: user_projects).pluck(:user_id).uniq
    
    # leave_request_ids = LeaveRequest.for_user(@user.id).overlaps(@timeline.date_from, @timeline.date_to).pluck(:id)
    # leave_approval_ids = LeaveRequest.where(user_id: projects_members).where.not(request_status: 0).overlaps(@timeline.date_from, @timeline.date_to).pluck(:id)


    # @scope_initial = LeaveRequest.where(id: (leave_request_ids + leave_approval_ids).uniq)
    @scope_initial = leave_requests_initial_users(projects_members)

    @region = params[:region] || @scope_initial.group('region').count.to_hash.keys
    
    scope = @scope_initial.where(region: @region)

    @timeline.leave_list = scope


    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
    end
  end

  def show_project
    @timeline = RedmineLeavesHolidays::Helpers::Timeline.new(params)
    user_ids = @project.members.pluck(:user_id)
    @timeline.project = @project

    # @scope_initial = LeaveRequest.where(user_id: user_ids).not_rejected.where.not(request_status: 0).overlaps(@timeline.date_from, @timeline.date_to)
    @scope_initial = leave_requests_initial_users(user_ids)

    @region = params[:region] || @scope_initial.group('region').count.to_hash.keys
    
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

end