class LeaveManagementRulesController < ApplicationController
  unloadable
  include LeavesHolidaysManagements
  before_action :find_project

  helper :leave_management_rules
  include LeaveManagementRulesHelper

  def new

    @sender_type = params[:sender_type] || LeavesHolidaysManagements.default_actor_type
    @sender_list_id ||= params[:sender_list_id]
    @sender_exception ||= params[:sender_exception]

    @action ||= params[:action_rule]
    
    @receiver_type = params[:receiver_type] || LeavesHolidaysManagements.default_actor_type
    @receiver_list_id ||= params[:receiver_list_id]
    @receiver_exception ||= params[:receiver_exception]
  end

  def create
    saved = false
    if params[:sender_list_id] && params[:receiver_list_id]
      params[:sender_list_id].each do |sender_id|
        params[:receiver_list_id].each do |receiver_id|
          @leave_management_rule = LeaveManagementRule.new(project: @project, sender: params[:sender_type].constantize.find(sender_id.to_i), receiver: params[:receiver_type].constantize.find(receiver_id.to_i), action: LeaveManagementRule.actions.select{|k,v| v == params[:action_rule].to_i}.keys.first)
          unless @leave_management_rule.save
            saved = true
          end
        end
      end
    end
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.js {
        redirect_to new_project_leave_management_rule_path unless saved
        }
    end
  end

  def index
    respond_to do |format|
      format.html { head 406 }
    end
  end

  private

  def find_project
    @project ||= Project.find(params[:project_id])
  end

  def redirect_to_settings_in_projects
    redirect_to settings_project_path(@project, :tab => 'leave_management')
  end

end