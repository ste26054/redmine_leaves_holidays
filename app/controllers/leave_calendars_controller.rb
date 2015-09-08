class LeaveCalendarsController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  include LeavesHolidaysDates
  include LeavesHolidaysTriggers

  helper :leave_requests
  include LeaveRequestsHelper

  before_action :set_user

  def show

    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end

    @year ||= Date.today.year
    @month ||= Date.today.month

    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)

    @leave_requests = {}

    user_projects = @user.leave_memberships.pluck(:project_id)
    projects_members = Member.includes(:project, :user).where(users: {status: 1}, project_id: user_projects).pluck(:user_id).uniq
    

    @leave_requests['requests'] ||= LeaveRequest.for_user(@user.id).overlaps(@calendar.startdt, @calendar.enddt)
    @leave_requests['approvals'] ||= LeaveRequest.where(user_id: projects_members).where.not(request_status: 0).overlaps(@calendar.startdt, @calendar.enddt)

  end

  private

  def set_user
    @user ||= User.current
  end


end