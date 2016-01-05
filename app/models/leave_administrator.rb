class LeaveAdministrator < ActiveRecord::Base
  unloadable

  default_scope { joins(:user).where(users: {status: 1}) }

  belongs_to :user
  belongs_to :project

  validates :user_id, presence: true
  validates :project_id, presence: true
end