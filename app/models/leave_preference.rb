class LeavePreference < ActiveRecord::Base
  unloadable
  include LeavesHolidaysLogic

  before_validation :set_user

  belongs_to :user
  attr_accessible :weekly_working_hours, :annual_leave_days_max, :region, :user_id


  validates :weekly_working_hours, presence: true, numericality: true, inclusion: { in: 0..80}
  validates :annual_leave_days_max, presence: true, numericality: true, inclusion: { in: 0..365}
  validates :region, presence: true
  validates :user_id, presence: true

  validate :validate_region

  private

  def set_user
    self.user_id = User.current.id
  end

  def validate_weekly_hours

  end

  def validate_leave_days

  end

  def validate_region
  	regions = LeavesHolidaysLogic.get_region_list
  	unless regions.include?(self.region.to_sym)
  		errors.add(:region, "is invalid")
  	end 
  end

end