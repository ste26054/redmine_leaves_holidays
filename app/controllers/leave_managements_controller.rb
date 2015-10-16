class LeaveManagementsController < ApplicationController
  unloadable
  before_action :find_project

  def new
    @leave_management = LeaveManagement.new
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