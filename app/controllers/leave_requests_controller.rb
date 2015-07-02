class LeaveRequestsController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  include LeavesHolidaysDates
  include LeavesHolidaysTriggers
  before_action :set_user
  before_action :set_leave_request, only: [:show, :edit, :update, :destroy, :submit, :unsubmit]
  
  before_filter :authenticate#, except: [:index, :new, :create]

  before_action :set_status, only: [:show, :destroy]
  before_action :set_issue_trackers
  before_action :set_checkboxes, only: [:edit, :update]


  helper :sort
  include SortHelper

  def index
    sort_init 'from_date', 'asc'

    sort_update 'id' => "#{LeaveRequest.table_name}.id",
                'created_at' => "#{LeaveRequest.table_name}.created_at",
                'from_date' => "#{LeaveRequest.table_name}.from_date",
                'to_date' => "#{LeaveRequest.table_name}.to_date"
    @leave_requests = {} 
    @leave_requests['requests'] ||= LeaveRequest.for_user(@user.id).reorder(sort_clause)

    if LeavesHolidaysLogic.has_view_all_rights(@user)
      @leave_requests['approvals'] ||= LeaveRequest.accepted.reorder(sort_clause)
    elsif LeavesHolidaysLogic.user_has_any_manage_right(@user)
      @leave_requests['approvals'] ||= LeaveRequest.processable_by(@user).reorder(sort_clause)
    else
    end

    contract_date = LeavesHolidaysLogic.user_params(@user, :contract_start_date).to_date
    renewal_date = LeavesHolidaysLogic.user_params(@user, :leave_renewal_date).to_date
    @period ||= LeavesHolidaysDates.get_contract_period_v2(contract_date, renewal_date)
    @remaining ||= LeavesHolidaysDates.total_leave_days_remaining_v2(@user, @period[:start], @period[:end])
    @taken ||= LeavesHolidaysDates.total_leave_days_taken(@user, @period[:start], @period[:end])


    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end

    @year ||= Date.today.year
    @month ||= Date.today.month

    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
  end

  def new
  	@leave = LeaveRequest.new
  end

  def create
  	@leave = LeaveRequest.new(leave_request_params)
  	if @leave.save
      self.info_flash
      redirect_to @leave
  	else
  		render new_leave_request_path
  	end
  end

  def submit
    unless @leave.request_status == "created" && @user == @leave.user
      render_403
      return
    else
      if (LeavesHolidaysLogic.user_params(@leave.user, :is_contractor) || @leave.is_non_approval_leave || LeavesHolidaysLogic.plugin_admins.include?(@leave.user.id))
        @leave.manage({acceptance_status: "accepted", comments: "AUTO_APPROVED"})
      else
        @leave.update_attribute(:request_status, "submitted")
        flash[:notice] = "Your leave request has been submitted for approval"
      end
      redirect_to @leave
    end
  end

  def unsubmit
    unless @leave.request_status == "submitted" && @user == @leave.user
      render_403
      return
    else
      @leave.update_attribute(:request_status, "created")
      flash[:notice] = "Your leave request has been unsubmitted."
      redirect_to @leave
    end
  end

  def show
  end

  def edit
  end

  def update
    if @leave.update(leave_request_params)
      self.info_flash
  		redirect_to @leave
  	else
  		render :edit
  	end
  end

  def destroy
    leave_relations = LeaveRequest.where(id: @leave.id)

    if leave_relations.processed.exists?
      if leave_relations.accepted.ongoing_or_finished.exists?
        flash[:error] = "You cannot cancel this leave as it has already been approved and is in the past"
        redirect_to leave_requests_path
        return
      end
      @status.update_attribute(:acceptance_status, "cancelled")
    end

    @leave.update_attribute(:request_status, "cancelled")
    redirect_to leave_requests_path
  end

  protected

  def info_flash
    if LeavesHolidaysLogic.plugin_admins.include?(@leave.user.id)
      flash[:notice] = "As you are an administrator, the Leave Request will automatically be approved once you click the \"Submit\" Button. Please make sure that all the details are correct."
    elsif LeavesHolidaysLogic.user_params(@leave.user, :is_contractor)
      flash[:notice] = "As you are a Contractor, the Leave Request will automatically be approved once you click the \"Submit\" Button. Please make sure that all the details are correct."
    elsif @leave.is_non_approval_leave
      flash[:notice] = "As leave reason selected is special (#{@leave.issue.subject}), the Leave Request will automatically be approved once you click the \"Submit\" Button. Please make sure that all the details are correct."
    else
      flash[:notice] = "Your leave request was successfully created. Do not forget to submit it for approval by hitting the \"Submit\" Button. You will then be able to edit it until it is processed."
    end  
  end

  private

  def set_leave_request
    begin
  	  @leave ||= LeaveRequest.unscoped.find(params[:id])
  	rescue ActiveRecord::RecordNotFound
  		render_404
  	end
  end

  def set_status
    if @leave.request_status == "processed"
      @status ||= LeaveStatus.for_request(@leave.id).first
    end
  end

  def set_checkboxes
  	@leave.leave_time_am = @leave.has_am?
  	@leave.leave_time_pm = @leave.has_pm?
  end

  def set_issue_trackers
  	@issues_trackers ||= LeavesHolidaysLogic.issues_list
  end

  def leave_request_params
  	params.require(:leave_request).permit(:from_date, :to_date, :user_id, :issue_id, :leave_time_am, :leave_time_pm, :comments)
  end

  def authenticate
    if params[:action].to_sym.in?([:index, :new, :create])
      render_403 unless LeavesHolidaysLogic.has_right(@user, @user, LeaveRequest, params[:action].to_sym)
    else
      render_403 unless LeavesHolidaysLogic.has_right(@user, @leave.user, @leave, params[:action].to_sym)
    end
    
  end

  def set_user
    @user ||= User.current
  end

end
