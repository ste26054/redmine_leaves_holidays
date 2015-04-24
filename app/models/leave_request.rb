class LeaveRequest < ActiveRecord::Base
  unloadable
  include LeavesHolidaysLogic
  
  belongs_to :user
  belongs_to :issue

  before_validation :set_user

  enum request_status: { pending: 0, processed: 1 }
  enum request_type: { am: 0, pm: 1, ampm: 2 }

  validates :from_date, date: true, presence: true
  validates :to_date, date: true, presence: true
  validates :user_id, presence: true
  validates :issue_id, presence: true
  validates :request_type, presence: true
  validates :request_status, presence: true

   validate :validate_set_request_type
   validate :validate_date_period
   validate :validate_issue
   

  attr_accessor :leave_time_am, :leave_time_pm
  attr_accessible :from_date, :to_date, :leave_time_am, :leave_time_pm, :issue_id, :comments, :user_id, :request_type

	private

	def validate_date_period
		if to_date != nil && from_date != nil && to_date < from_date
			errors.add(:base,"The Leave period entered is invalid")
		end

    if to_date != nil && from_date != nil && self.request_type != "ampm" && (to_date - from_date).to_i > 0
      errors.add(:base,"Half day leaves cannot be more than 1 day")
    end
	end

	def validate_issue
		if issue_id != nil && !((issues_list.collect {|t| t.id }).include?( issue_id))
			errors.add(:issue, "is invalid")
		end
	end

  def validate_set_request_type
    
    self.leave_time_am.to_i == 0 ? (am = 0) : (am = 1)
    self.leave_time_pm.to_i == 0 ? (pm = 0) : (pm = 1)

    if am == 1 && pm == 0
      self.request_type = 0
    elsif am == 0 && pm == 1
      self.request_type = 1
    elsif am == 1 && pm == 1
      self.request_type = 2
    else
      errors.add(:leave_time_am, "is invalid")
      errors.add(:leave_time_pm, "is invalid")
    end
  end

  def set_user
    self.user_id = User.current.id
  end
	
end
