class LeaveTimelinesController < ApplicationController
  unloadable

  helper :leave_requests
  include LeaveRequestsHelper
  helper :leave_timelines
  
  before_action :set_user, :find_project

  def show
    @timeline = RedmineLeavesHolidays::Helpers::Timeline.new(params)

    unless @project
    user_projects = @user.leave_memberships.pluck(:project_id)
    projects_members = Member.includes(:project, :user).where(users: {status: 1}, project_id: user_projects).pluck(:user_id).uniq
    
    leave_request_ids = LeaveRequest.for_user(@user.id).overlaps(@timeline.date_from, @timeline.date_to).pluck(:id)
    leave_approval_ids = LeaveRequest.where(user_id: projects_members).where.not(request_status: 0).overlaps(@timeline.date_from, @timeline.date_to).pluck(:id)

      @timeline.leave_list = LeaveRequest.where(id: (leave_request_ids + leave_approval_ids).uniq)
    else
      @timeline.leave_list = LeaveRequest.all.overlaps(@timeline.date_from, @timeline.date_to).not_rejected
    end

    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
    end
  end

  private

  def set_user
    @user ||= User.current
  end

  def find_project
    if params.has_key?(:project_id)
      @project ||= Project.find(params[:project_id])
    end
  end

end