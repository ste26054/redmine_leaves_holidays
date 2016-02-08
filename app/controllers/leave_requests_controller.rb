class LeaveRequestsController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  include LeavesHolidaysDates
  include LeavesHolidaysTriggers
  include LeavesHolidaysPermissions

  before_action :set_user
  before_action :set_leave_preferences
  before_action :set_leave_request, only: [:show, :edit, :update, :destroy, :submit, :unsubmit]
  
  before_action :authenticate, except: [:index, :feedback_new, :feedback_send]
  before_action :authenticate_feedback, only: [:feedback_new, :feedback_send]
  before_action :auth_handle_index, only: [:index]

  before_action :set_status, only: [:show, :destroy]
  before_action :set_issue_trackers
  before_action :set_checkboxes, only: [:edit, :update]
  before_action :set_check_ok
  before_action :set_notifications, only: [:new, :create, :edit, :update]
  before_action :check_actions_are_notified, only: [:new, :create, :submit, :unsubmit, :edit, :update, :destroy]

  helper :sort
  include SortHelper

  def index
    sort_init 'id', 'asc'

    sort_update 'id' => "#{LeaveRequest.table_name}.id",
                'created_at' => "#{LeaveRequest.table_name}.created_at",
                'from_date' => "#{LeaveRequest.table_name}.from_date",
                'to_date' => "#{LeaveRequest.table_name}.to_date"

    @period ||= @user.leave_period
    @remaining ||= @user.days_remaining
    @taken ||= @user.days_taken_accepted

    scope ||= LeaveRequest.for_user(@user.id)

    @include_past_leave = params[:include_past_leave] || "false"

    if @include_past_leave == "false"
      scope = scope.when(['ongoing', 'coming'])
    end
    @limit = per_page_option

    @leave_count = scope.count
    @leave_pages = Paginator.new @leave_count, @limit, params['page']
    @offset ||= @leave_pages.offset
    @leave_requests =  scope.order(sort_clause).limit(@limit).offset(@offset).to_a
  end

  def new
  	@leave = LeaveRequest.new
    @leave.leave_time_am = true
    @leave.leave_time_pm = true
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
    unless @leave.request_status == "created"
      render_403
      return
    else
      if LeavesHolidaysLogic.user_params(@leave.user, :is_contractor) || @leave.is_non_approval_leave || @leave.user.can_self_approve_requests?
        @leave.manage({acceptance_status: "accepted", comments: "AUTO_APPROVED"})
      else
        @leave.update_attribute(:request_status, "submitted")
        flash[:notice] = "Your leave request has been submitted for approval"
      end
      redirect_to @leave
    end
  end

  def unsubmit
    unless @leave.request_status == "submitted"
      render_403
      return
    else
      @leave.update_attribute(:request_status, "created")
      flash[:notice] = "Your leave request has been unsubmitted."
      redirect_to @leave
    end
  end

  def show
    @auth_view_metrics = @is_consulted || @is_notified || @is_managing || @has_view_all_rights
    @auth_manage = authenticate_leave_status({action: :new})
    @auth_consult = authenticate_leave_votes({action: :new})
  end

  def edit
    unless @leave.request_status == "created"
      render_403
      return
    end
  end

  def update
    unless @leave.request_status == "created"
      render_403
      return
    end
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
        flash[:error] = "You cannot cancel this leave as it has already been approved and is in the past. Please ask your line manager to reject it if necessary."
        redirect_to leave_requests_path
        return
      end
      @status.update_attribute(:acceptance_status, "cancelled")
    end

    @leave.update_attribute(:request_status, "cancelled")
    redirect_to leave_requests_path
  end

  def feedback_new
  end

  def feedback_send
    if params[:leave_feedback] && params[:leave_feedback].squish.size > 0
      # see @redmine source for textile formatting
      text = params[:leave_feedback].to_s.strip.gsub(%r{<pre>(.*?)</pre>}m, '[...]')
      @content = "#{ll(Setting.default_language, :text_user_wrote, @user)}\n> "
      @content << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
      send_general_notification_email(@content)
    end
  end

  protected

  def info_flash
    if @leave.user.can_self_approve_requests?
      flash[:notice] = "As you are an administrator, the Leave Request will automatically be approved once you click the \"Submit\" Button. Please make sure that all the details are correct."
    elsif LeavesHolidaysLogic.user_params(@leave.user, :is_contractor)
      flash[:notice] = "As you are a Contractor, the Leave Request will automatically be approved once you click the \"Submit\" Button. Please make sure that all the details are correct."
    elsif @leave.is_non_approval_leave
      flash[:notice] = "As leave reason selected is special (#{@leave.issue.subject}), the Leave Request will automatically be approved once you click the \"Submit\" Button. Please make sure that all the details are correct."
    else
      flash[:notice] = "Your leave request was successfully created. Do not forget to submit it for approval by hitting the \"Submit\" Button. You will then be able to edit it until it is processed."
    end  
  end

  def set_notifications
    @is_contractor = @user.is_contractor

    if @is_contractor
      @managed_list = []
      @consult_list = []
    else
      @managed_list = @user.project_managed_by_notification_list
      @consult_list = @user.project_consults_full_list.values.flatten.uniq
    end
    
    @notify_approved_full = (LeavesHolidaysLogic.users_with_view_all_right + @user.project_notify_full_list.values).flatten.uniq.sort_by(&:name)

  end

  def set_check_ok
    @is_ok_to_submit_leave = @user.are_leave_notifications_ok?
  end

  def check_actions_are_notified
    unless @is_ok_to_submit_leave
      
      msg = "The system does not have enough information to determine who is able to process your leave requests. Please, ask your manager to update your leave management rules and retry. An email was sent to the administrator."
      flash[:error] = msg
      send_general_notification_email(msg)
      redirect_to leave_requests_path
    end
  end

  private

  def send_general_notification_email(text)
    users_to_send_mail = LeavesHolidaysLogic.plugin_users_errors_recipients
    Mailer.leave_general_notification(users_to_send_mail, @user, text).deliver
  end

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
  	@issues_trackers ||= LeavesHolidaysLogic.issues_list(@user)
  end

  def leave_request_params
  	params.require(:leave_request).permit(:from_date, :to_date, :user_id, :issue_id, :leave_time_am, :leave_time_pm, :comments)
  end

  def authenticate
    @auth_leave = authenticate_leave_request(params)
    render_403 unless @auth_leave
  end

  def auth_handle_index
    return if authenticate_leave_request(params)
    redirect_to leave_approvals_path and return if authenticate_leave_status(params)
    redirect_to leave_preferences_path and return if authenticate_leave_preferences(params)
    render_403
  end

  def authenticate_feedback
    return if @user.has_leave_plugin_access? || @user.allowed_to?(:manage_leave_management_rules, nil, :global => true)
    render_403
  end

  def set_user
    @user = User.current
  end

  def set_leave_preferences
    @leave_preferences ||= @user.leave_preferences
  end

end
