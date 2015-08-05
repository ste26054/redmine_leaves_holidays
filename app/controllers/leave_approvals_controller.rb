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
    
    manage = true
    @limit = per_page_option

    if LeavesHolidaysLogic.has_view_all_rights(@user)
      scope ||= LeaveRequest.accepted
    elsif LeavesHolidaysLogic.user_has_any_manage_right(@user)
      scope ||= LeaveRequest.processable_by(@user)
    else
      manage = false
    end

    if manage
      @leave_count = scope.count
      @leave_pages = Paginator.new @leave_count, @limit, params['page']
      @offset ||= @leave_pages.offset
      @leave_approvals =  scope.order(sort_clause).limit(@limit).offset(@offset).to_a
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