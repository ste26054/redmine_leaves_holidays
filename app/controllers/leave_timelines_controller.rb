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
    
    leave_request_ids = LeaveRequest.for_user(@user.id).overlaps(@timeline.date_from, @timeline.date_to).pluck(:id)
    leave_approval_ids = LeaveRequest.where(user_id: projects_members).where.not(request_status: 0).overlaps(@timeline.date_from, @timeline.date_to).pluck(:id)

    @timeline.leave_list = LeaveRequest.where(id: (leave_request_ids + leave_approval_ids).uniq)


    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
    end
  end

  def show_project
    @timeline = RedmineLeavesHolidays::Helpers::Timeline.new(params)
    user_ids = @project.members.pluck(:user_id)
    @timeline.project = @project
    @timeline.leave_list = LeaveRequest.where(user_id: user_ids).not_rejected.where.not(request_status: 0).overlaps(@timeline.date_from, @timeline.date_to)
  
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

end