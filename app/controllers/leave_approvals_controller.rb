class LeaveApprovalsController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  include LeavesHolidaysDates
  include LeavesHolidaysTriggers

  helper :leave_requests
  include LeaveRequestsHelper

  before_action :set_user
  before_filter :authenticate

  helper :sort
  include SortHelper


  def index
    sort_init 'from_date', 'asc'

    sort_update 'id' => "#{LeaveRequest.table_name}.id",
                'created_at' => "#{LeaveRequest.table_name}.created_at",
                'from_date' => "#{LeaveRequest.table_name}.from_date",
                'to_date' => "#{LeaveRequest.table_name}.to_date"


    if LeavesHolidaysLogic.has_view_all_rights(@user)
      @leave_approvals ||= LeaveRequest.accepted.reorder(sort_clause)
    elsif LeavesHolidaysLogic.user_has_any_manage_right(@user)
      @leave_approvals ||= LeaveRequest.processable_by(@user).reorder(sort_clause)
    else
    end

  end

  private

  def authenticate
    render_403 unless LeavesHolidaysLogic.has_right(@user, @user, LeaveRequest, params[:action].to_sym)
  end

  def set_user
    @user ||= User.current
  end


end