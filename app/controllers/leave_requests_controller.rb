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
  	params[:leave_request][:user_id] = User.current.id

	@leave = LeaveRequest.new(params[:leave_request])
	@issues_trackers = issues_list
	if @leave.save
		redirect_to :action => 'index'
	else
		render :action => 'new'
	end
  	# redirect_to :action => 'new', :via => :get
  	# Rails.logger.info "BEFORE SAVE"
  	# if @leave.save
   #    Rails.logger.info 'leave was successfully created.'
   #    redirect_to :action => 'index'
   #  else
   #    Rails.logger.info 'ERROR WHILE CREATING LEAVE'
   #    Rails.logger.info "ERROR MESSAGES: #{@leave.errors.full_messages}"
   #    redirect_to :action => 'new'
   #  end
   	
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
