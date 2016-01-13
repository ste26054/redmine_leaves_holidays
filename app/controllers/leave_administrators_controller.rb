class LeaveAdministratorsController < ApplicationController
  unloadable
  before_action :find_project
  before_action :authorize

  helper :leave_management_rules

  def edit
    @leave_administrators = LeaveAdministrator.where(project: @project).pluck(:user_id)
  end

  def update
    if params[:leave_administrator_ids]
      LeaveAdministrator.unscoped.destroy_all(project: @project)
      user_ids = User.all.active.where(id: params[:leave_administrator_ids]).pluck(:id)
      user_ids.each do |admin_id|
        l = LeaveAdministrator.new(project: @project, user_id: admin_id)
        l.save
      end
    end
  end

  def clear
    LeaveAdministrator.unscoped.destroy_all(project: @project)
    render :update
  end


  private

  def find_project
    @project ||= Project.find(params[:project_id])
  end

end