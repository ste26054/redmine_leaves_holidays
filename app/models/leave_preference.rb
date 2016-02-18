class LeavePreference < ActiveRecord::Base
  unloadable
  include Redmine::Utils::DateCalculation
  include LeavesHolidaysLogic

  # before_validation :set_user

  default_scope { 
    joins(:user).where(users: {status: 1}) }

  belongs_to :user
  attr_accessible :weekly_working_hours, :annual_leave_days_max, :region, :user_id, :contract_start_date, :contract_end_date, :extra_leave_days, :is_contractor,:annual_max_comments,:leave_renewal_date, :pending_day_count, :overall_percent_alloc, :can_create_leave_requests


  validates :weekly_working_hours, presence: true, numericality: true, inclusion: { in: 0..80}
  validates :annual_leave_days_max, presence: true, numericality: true, inclusion: { in: 0..365}
  validates :contract_start_date, presence: true, date: true
  validates :contract_end_date, date: true

  validates :leave_renewal_date, presence: true, date: true

  validates :extra_leave_days, presence: true, numericality: true, inclusion: { in: -365..365}
  validates :pending_day_count, numericality: true, inclusion: { in: -365..365}
  validates :region, presence: true
  validates :user_id, presence: true
  validates :is_contractor, :inclusion => {:in => [true, false]}

  validates :overall_percent_alloc, numericality: true, inclusion: { in: 0..100}

  validate :validate_region
  validate :validate_contract_end_date

  scope :for_user, ->(uid) { where(user_id: uid) }

  before_save :perform_event_backup, :on => [:create, :update]
  before_save :handle_incorrect_region, :on => [:update]

  def css_classes
    s = "leave-preference user-#{self.user_id}"
    s << ' needs-attention' if self.id && self.pending_day_count && self.pending_day_count != 0
    return s
  end

  def is_region_valid?
    return region.to_sym.in?(Holidays.regions)
  end

  private

  def default_days_leaves_months
  	return annual_leave_days_max.to_f / 12.0
  end

  def daily_working_hours
    return LeavesHolidaysLogic.user_params(user, :weekly_working_hours).to_f / (7.0 - non_working_week_days.count )
  end

  def validate_region
  	regions = RedmineLeavesHolidays::Setting.defaults_settings(:available_regions)
  	unless regions.include?(self.region)
  		errors.add(:region, "is invalid")
  	end 
  end

  def validate_contract_end_date
    if contract_start_date && contract_end_date
      if contract_start_date > contract_end_date
        errors.add(:contract_end_date, "cannot be > to contract start date")
      end
    end
  end

  def perform_event_backup
    leave_pref = self.user.leave_preferences
    event_count = LeaveEvent.where(user_id: self.user_id).count
    if event_count == 0
      event = LeaveEvent.new(user_id: self.user_id, event_type: "initial_backup", comments: "Initial backup before first changes")
      event.event_data = leave_pref.attributes
      event.save
    end
  end

  def handle_incorrect_region
    if is_region_valid?
      former_lp = self.user.leave_preferences
      unless former_lp.is_region_valid?
        LeaveRequest.for_user(self.user_id).where(region: former_lp.region).update_all(region: self.region)
      end
    end
  end


end