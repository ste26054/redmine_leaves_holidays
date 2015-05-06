class LeaveStatusesController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  before_action :set_leave_request
  before_action :set_leave_status
  before_action :view_status, only: [:show]
  before_action :manage_status, except: [:show]
  

  def new
     # @leave = LeaveRequest.find(params[:leave_request_id])
     # @status = LeaveStatus.new if @status == nil
    if @status != nil
      # redirect_to leave_request_leave_status_path
      redirect_to edit_leave_request_leave_statuses_path
    else
      @status = LeaveStatus.new
    end
  end

  def create
    @leave = LeaveRequest.find(params[:leave_request_id])

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
       # redirect_to edit_leave_request_leave_statuses_path
       redirect_to @status
    end
  end

  def destroy
      render_403
      # @status.destroy
      # redirect_to @leave
  end

  private

  def leave_status_params
    params.require(:leave_status).permit(:leave_request_id, :processed_date, :user_id, :comments, :acceptance_status).merge(timestamp: @timestamp)
  end

  def set_leave_status
    @status = LeaveStatus.where(leave_request_id: @leave.id).first if @status == nil
  end

  def set_leave_request
    begin
      @leave = LeaveRequest.find(params[:leave_request_id]) if @leave == nil
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

  def view_status
    render_403 unless LeavesHolidaysLogic.is_allowed_to_view_status(User.current, @leave.user)
  end

  def manage_status
    render_403 unless LeavesHolidaysLogic.is_allowed_to_manage_status(User.current, @leave.user)
  end

end
