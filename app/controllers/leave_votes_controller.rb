class LeaveVotesController < ApplicationController
  unloadable
  before_action :set_user
  before_action :set_leave_request
  before_action :set_leave_vote
  before_action :check_change, only: [:new, :create, :edit, :update]


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
  	@votes = LeaveVote.for_request(@leave.id)
  end

  def edit
  end

  def update
    if @vote.update(leave_vote_params)
       redirect_to @leave
    else
       # redirect_to edit_leave_request_leave_statuses_path
       redirect_to @vote
    end
  end


  private

  def leave_vote_params
    params.require(:leave_vote).permit(:leave_request_id, :id, :user_id, :comments, :vote)
  end

  def set_user
  	@user = User.current
  end

  def set_leave_request
    begin
      @leave = LeaveRequest.find(params[:leave_request_id]) if @leave == nil
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

  def set_leave_vote
    @vote = LeaveVote.for_user(@user.id).where(leave_request_id: @leave.id).first if @vote == nil
  end

  def check_change
  	render_403 unless !LeavesHolidaysLogic.is_allowed_to_vote_request(@user, @leave.user).empty?
  end


end