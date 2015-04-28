class LeaveRequestsController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  before_action :set_leave_request, only: [:show, :edit, :update, :destroy]
  before_action :set_issue_trackers
  before_action :set_checkboxes, only: [:edit, :update]

  def index
  	# @leave_requests = LeaveRequest.where(user_id: User.current.id)
  	@leave_requests = LeaveRequest.for_user(User.current.id)#.pending


  end

  def new
  	@leave = LeaveRequest.new if @leave == nil
    # Rails.logger.info "ROLES: #{User.current.projects_by_role.to_yaml}"
  end

  def create
  	@leave = LeaveRequest.new(leave_request_params)
    
  	if @leave.save
      # @status = LeaveStatus.new
      # @leave.leave_status = @status
  		redirect_to @leave #:action => 'index'
  	else
  		render :action => 'new'
  	end
  end

  def show
  end

  def edit
    #Only the 
  end

  def update
    if @leave.update(leave_request_params)
  		redirect_to @leave #:action => 'index'
  	else
  		render :edit
  	end
  end

  def destroy
    #Should not delete the leave request in DB
    #Whatever the status of the leave, should notify the users who were informed of the request creation
    #A leave request which already took place cannot be deleted = Hours won't be deletable.
  end

  private

  def set_leave_request
  	@leave = LeaveRequest.where(id: params[:id], user_id: User.current.id).first
    Rails.logger.info "SET LEAVE REQUEST: #{@leave}"
  	if @leave == nil
  		render_403
  	end
  end

  def set_checkboxes
  	@leave.leave_time_am = @leave.has_am?
  	@leave.leave_time_pm = @leave.has_pm?
  end

  def set_issue_trackers
  	@issues_trackers = issues_list
  end

  def leave_request_params
  	params.require(:leave_request).permit(:from_date, :to_date, :user_id, :issue_id, :leave_time_am, :leave_time_pm, :comments)
  end
end
