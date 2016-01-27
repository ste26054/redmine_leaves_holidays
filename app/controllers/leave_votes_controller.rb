class LeaveVotesController < ApplicationController
  unloadable

  before_action :set_user, :set_leave_request

  before_filter :authenticate, only: [:new, :create]

  before_action :set_leave_vote, :set_leave_votes

  before_filter :authenticate_edit, only: [:edit, :update]
  

  helper :sort
  include SortHelper

  def new
    if @vote != nil
      redirect_to edit_leave_request_leave_vote_path(@leave, @vote)
    else
      @vote = LeaveVote.new
    end
  end

  def create
    @leave = LeaveRequest.find(params[:leave_request_id])

    @vote = LeaveVote.new(leave_vote_params) if @vote == nil
    @vote.leave_request = @leave

    if @vote.save
       @leave.update_attribute(:request_status, "processing")
       redirect_to @leave
    else
       redirect_to new_leave_request_leave_vote_path(@leave)
    end
  end

  def index
    render_403 unless LeavesHolidaysLogic.has_right(User.current, @leave.user, LeaveVote, :read, @leave)
  end

  def edit
  end

  def update
    if @vote.update(leave_vote_params)
       redirect_to @leave
    else
       redirect_to @vote
    end
  end


  private

  def leave_vote_params
    params.require(:leave_vote).permit(:leave_request_id, :id, :user_id, :comments, :vote)
  end

  def set_user
  	@user ||= User.current
  end

  def set_leave_request
    begin
      @leave ||= LeaveRequest.find(params[:leave_request_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

  def set_leave_vote
    begin
      @vote ||= LeaveVote.for_user(@user.id).where(leave_request_id: @leave.id).first
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

  def set_leave_votes
    @votes ||= LeaveVote.for_request(@leave.id)
  end

  # TO_CHECK
  def authenticate
    render_403 unless LeavesHolidaysLogic.has_right(@user, @leave.user, LeaveVote, params[:action].to_sym, @leave)
  end

  # TO_CHECK
  def authenticate_edit
    if @vote == nil
      render_404
      return
    end
    render_403 unless LeavesHolidaysLogic.has_right(@user, @vote.user, @vote, :edit)
  end  

end