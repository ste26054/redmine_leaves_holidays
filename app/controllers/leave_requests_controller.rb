class LeaveRequestsController < ApplicationController
  unloadable
  include LeavesHolidaysLogic


  def index
  	@leave_requests = LeaveRequest.where(user_id: User.current.id) #.all
  end

  def new
  	@leave = LeaveRequest.new if @leave == nil
  	@issues_trackers = issues_list

  	Rails.logger.info "CALLED NEW ***************** #{@leave}"

  end

  def create
	@leave = LeaveRequest.new(leave_request_params)
	@issues_trackers = issues_list
	if @leave.save
		redirect_to @leave #:action => 'index'
	else
		render :new
	end
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def leave_request_params
  	params.require(:leave_request).permit(:from_date, :to_date, :user_id, :issue_id, :leave_time_am, :leave_time_pm)
  end
end
