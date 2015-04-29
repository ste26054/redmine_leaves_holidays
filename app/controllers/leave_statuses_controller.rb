class LeaveStatusesController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  before_action :set_leave_request
  before_action :set_leave_status


  def new
    Rails.logger.info "IN STATUSES NEW"
     # @leave = LeaveRequest.find(params[:leave_request_id])
     # @status = LeaveStatus.new if @status == nil
     Rails.logger.info "STATUS: #{@status}, LEAVE: #{@leave}"
    if @status != nil
      # redirect_to leave_request_leave_status_path
      redirect_to edit_leave_request_leave_statuses_path
    else
      @status = LeaveStatus.new
    end
  end

  def create
    @leave = LeaveRequest.find(params[:leave_request_id])

    Rails.logger.info "IN STATUSES CREATE"
    @status = LeaveStatus.new(leave_status_params) if @status == nil
    @status.leave_request = @leave

    if @status.save
       @leave.update_attribute(:request_status, "processed")

       redirect_to @leave
    else
       redirect_to new_leave_request_leave_statuses_path
    end
  end

  def show
  end

  def edit
  end

  def update
    if @status.update(leave_status_params)
       redirect_to @leave
    else
       redirect_to edit_leave_request_leave_statuses_path
    end
  end

  def destroy
      @status.destroy
      redirect_to @leave
  end

  private

  def leave_status_params
    params.require(:leave_status).permit(:leave_request_id, :processed_date, :user_id, :comments, :acceptance_status)
  end

  def set_leave_status
    @status = LeaveStatus.where(leave_request_id: @leave.id).first if @status == nil
    Rails.logger.info "IN SET LEAVE STATUS: LEAVE ID: #{@leave.id}, STATUS: #{@status}"
  end

  def set_leave_request
    @leave = LeaveRequest.find(params[:leave_request_id]) if @leave == nil
    Rails.logger.info "SET LEAVE REQUEST: #{@leave}"
    if @leave == nil
      render_404
    end
  end

  def view_status
    render_403 unless LeavesHolidaysLogic.is_allowed_to_view_status(User.current, @leave)
  end

  def manage_status
    render_403 unless LeavesHolidaysLogic.is_allowed_to_manage_status(User.current, @leave)
  end

end
