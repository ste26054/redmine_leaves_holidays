class LeaveStatusesController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  before_action :set_leave_request
  before_action :set_leave_status
  before_action :set_leave_vote
  before_action :set_vote_list

  before_filter :authenticate

  helper :sort
  include SortHelper

  def new
    if @status != nil
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
  end

  private

  def leave_status_params
    params.require(:leave_status).permit(:leave_request_id, :processed_date, :user_id, :comments, :acceptance_status)
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

  def set_leave_vote
      @votes = LeaveVote.for_request(@leave.id) if @votes == nil
  end

  def set_vote_list
    # list = LeavesHolidaysLogic.vote_list_left(@leave)
    # Rails.logger.info "SET VOTE LIST: #{list}"
    # @vote_list = []
    # list.each do |entry|
    #   entry.each do |l|
    #     @vote_list << {user: User.find(l[:user_id]), role_name: l[:name], project_name: l[:project]}
    #   end
    # end
    # Rails.logger.info "LIST IS: #{@vote_list}"
    @vote_list = LeavesHolidaysLogic.vote_list_left(@leave)

  end

  def authenticate
    unless (@status != nil && params[:action].to_sym == :new)
      render_403 unless LeavesHolidaysLogic.has_right(User.current, @leave.user, LeaveStatus, params[:action].to_sym, @leave)
    end
  end

end
