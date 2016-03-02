class LeaveRulesController < ApplicationController
  unloadable
  
  helper :leave_requests
  include LeaveRequestsHelper
  include LeaveHolidaysCommon

  before_action :set_user
  before_action :set_leave_reasons

  def index
    @leave_rules = LeaveRule.all
    @leave_reasons_undefined = @leave_reasons.where.not(id: @leave_rules.pluck(:issue_id))
  end

  def new
    @leave_rule = LeaveRule.find_by(issue_id: params[:issue_id])
    if @leave_rule
      redirect_to edit_leave_rule_path(@leave_rule)
      return
    end
    @leave_rule = LeaveRule.new(params[:leave_rule])
    @leave_rule.issue_id = params[:issue_id]
  end

  def create
    @leave_rule = LeaveRule.new(params[:leave_rule])
    if @leave_rule.save
      redirect_to leave_rules_path
      return
    end
    new
    render :action => 'new'
  end

  def edit
    @leave_rule ||= LeaveRule.find(params[:id])
  end

  def update
    @leave_rule = LeaveRule.find(params[:id])
    if @leave_rule.update_attributes(params[:leave_rule])
      flash[:notice] = l(:notice_successful_update)
      redirect_to leave_rules_path(:page => params[:page])
      return
    end
    edit
    render :action => 'edit'
  end

private

  def set_leave_reasons
    @leave_reasons = LeavesHolidaysLogic.issues_list
  end

end