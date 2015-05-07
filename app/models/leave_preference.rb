class LeavePreference < ActiveRecord::Base
  unloadable
  include LeavesHolidaysLogic

  before_validation :set_user

  belongs_to :user
  attr_accessible :weekly_working_hours, :annual_leave_days_max, :region, :user_id


  validates :weekly_working_hours, presence: true
  validates :annual_leave_days_max, presence: true
  validates :region, presence: true
  validates :user_id, presence: true

  private

  def set_user
    self.user_id = User.current.id
  end

end