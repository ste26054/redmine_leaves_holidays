class LeaveRequestsController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  include LeavesHolidaysDates
  include LeavesHolidaysTriggers
  include LeavesHolidaysPermissions

  before_action :check_plugin_install
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
  helper :custom_fields
  helper :attachments
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
    @leave.leave_time_am = "1"
    @leave.leave_time_pm = "1"
  end

  def create
  	@leave = LeaveRequest.new(leave_request_params)
    @leave.safe_attributes = params[:leave_request]
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
        flash[:notice] = l(:leave_notice_submitted)
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
      flash[:notice] = l(:leave_notice_unsubmitted)
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
    @leave.safe_attributes = params[:leave_request]
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
        flash[:error] = l(:leave_error_cannot_cancel_approved_in_past)
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

  def leave_length
    if params["from_date"] != "" && params["to_date"] != ""
      from = params["from_date"].to_date
      to = params["to_date"].to_date
      if from <= to
        region = @user.leave_preferences.region
        am_checked = params["leave_time_am"] == "true" 
        pm_checked = params["leave_time_pm"] == "true"
        if am_checked || pm_checked
          type = 0
          type = 2 if am_checked && pm_checked
          @length = LeaveRequest.new(from_date: from, to_date: to, region: region, request_type: type).actual_leave_days
          @valid = true
        end
      end
    end
    render :layout => false
  end

  def leave_issue_description
    if params["issue_id"] != ""
      issue_id = params["issue_id"].to_i
      @issue = @issues_trackers.select{|i| i.id == issue_id}.first
    end
    render :layout => false
  end

  protected

  def info_flash
    if @leave.user.can_self_approve_requests?
      flash[:notice] = l(:leave_notice_auto_approve_leave_admin)
    elsif LeavesHolidaysLogic.user_params(@leave.user, :is_contractor)
      flash[:notice] = l(:leave_notice_auto_approve_contractor)
    elsif @leave.is_non_approval_leave
      flash[:notice] = l(:leave_notice_non_approval_leave, subject: @leave.issue.subject)
    else
      flash[:notice] = l(:leave_notice_created)
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
      
      msg = l(:leave_error_not_enough_data)
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
  	@leave.leave_time_am = @leave.has_am? ? "1" : "0"
  	@leave.leave_time_pm = @leave.has_pm? ? "1" : "0"
  end

  def set_issue_trackers
  	@issues_trackers ||= LeavesHolidaysLogic.issues_list(@user)
  end

  def leave_request_params
  	params.require(:leave_request).permit(:from_date, :to_date, :user_id, :issue_id, :leave_time_am, :leave_time_pm, :comments, :custom_field_values)
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

  def check_plugin_install
    unless LeavesHolidaysLogic.plugin_configured?
      flash[:error] = l(:leave_error_plugin_not_configured)
      redirect_to home_path
      return
    end
  end

end
