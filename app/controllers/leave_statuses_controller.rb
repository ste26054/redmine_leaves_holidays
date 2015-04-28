class LeaveStatusesController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  before_action :set_leave_request
  before_action :set_leave_status


  def index
  end

  def new
    Rails.logger.info "IN STATUSES NEW"
    @leave = LeaveRequest.find(params[:leave_request_id])
    # @status = LeaveStatus.new if @status == nil
    if @status != nil
      render_403
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
    #   # @status = LeaveStatus.new
    #   # @leave.leave_status = @status
       redirect_to @leave #:action => 'index'
    else
       render :action => 'new'
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

  def leave_status_params
    params.require(:leave_status).permit(:leave_request_id, :processed_date, :user_id, :comments, :acceptance_status)
  end

  def set_leave_status
    @status = LeaveStatus.where(leave_request_id: @leave.id).first
    Rails.logger.info "IN SET LEAVE STATUS: LEAVE ID: #{@leave.id}, STATUS: #{@status}"
  end

  def set_leave_request
    @leave = LeaveRequest.where(id: params[:leave_request_id]).first
    Rails.logger.info "SET LEAVE REQUEST: #{@leave}"
    if @leave == nil
      render_403
    end
  end

end
