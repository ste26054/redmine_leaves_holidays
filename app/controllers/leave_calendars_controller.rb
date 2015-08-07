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

    @leave_requests['requests'] ||= LeaveRequest.overlaps(@calendar.startdt, @calendar.enddt).for_user(@user.id)

    if LeavesHolidaysLogic.has_view_all_rights(@user)
      @leave_requests['approvals'] ||= LeaveRequest.overlaps(@calendar.startdt, @calendar.enddt).accepted
    elsif LeavesHolidaysLogic.user_has_any_manage_right(@user)
      @leave_requests['approvals'] ||= LeaveRequest.overlaps(@calendar.startdt, @calendar.enddt).processable_by(@user)
    else
    end

  end

  private

  def set_user
    @user ||= User.current
  end


end