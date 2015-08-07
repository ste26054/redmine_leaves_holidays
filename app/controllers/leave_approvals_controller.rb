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
    @status = params[:status] || ['1','4']

    manage = true
    @limit = per_page_option

    scope ||= LeaveRequest.processable_by(@user)

    @status_count = scope.group('request_status').count.to_hash
    scope = scope.status(@status)

    @when = params[:when] || ['ongoing', 'coming']
    scope = scope.when(@when)

    @reason = params[:reason] || LeavesHolidaysLogic.issues_list.pluck(:id)
    scope = scope.reason(@reason)

    @show_rejected = params[:show_rejected] || "false"


    @region = params[:region] || LeaveRequest.group('region').count.to_hash.keys
    scope = scope.where(region: @region)

    if @show_rejected == "false"
      scope = scope.not_rejected
    end

    @leave_count = scope.count
    @leave_pages = Paginator.new @leave_count, @limit, params['page']
    @offset = @leave_pages.offset
    @leave_approvals =  scope.order(sort_clause).limit(@limit).offset(@offset).to_a


  end

  private

  def authenticate
    render_403 unless LeavesHolidaysLogic.has_right(@user, @user, LeaveRequest, params[:action].to_sym)
  end

  def set_user
    @user ||= User.current
  end


end