class LeaveAdministrator < ActiveRecord::Base
  unloadable

  default_scope { 
    system_leave_project_ids = Project.system_leave_projects.pluck(:id)
    joins(:user, :project).where(users: {status: 1}, projects: {status: 1, id: system_leave_project_ids}) }

  belongs_to :user
  belongs_to :project

  validates :user_id, presence: true
  validates :project_id, presence: true
end