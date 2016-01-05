class LeaveAdministratorsController < ApplicationController
  unloadable
  before_action :find_project
  before_action :authorize

  def edit

  end

  def update

  end


  private

  def find_project
    @project ||= Project.find(params[:project_id])
  end

end