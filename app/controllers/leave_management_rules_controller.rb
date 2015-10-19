class LeaveManagementRulesController < ApplicationController
  unloadable
  include LeavesHolidaysManagements
  before_action :find_project

  helper :leave_management_rules
  include LeaveManagementRulesHelper

  def new
    #@leave_management_rule = LeaveManagementRule.new(:project => @project)

    @sender_type = params[:sender_type] || LeavesHolidaysManagements.default_actor_type
    @sender_list_id ||= params[:sender_list_id]

    @action ||= params[:action_rule]
    
    @receiver_type = params[:receiver_type] || LeavesHolidaysManagements.default_actor_type
    @receiver_list_id ||= params[:receiver_list_id]

  end

  def create
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.js {
        
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