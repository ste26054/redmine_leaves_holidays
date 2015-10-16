class LeaveManagementsController < ApplicationController
  unloadable
  before_action :find_project

  def new
    @leave_management = LeaveManagement.new
  end

  def create

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

end