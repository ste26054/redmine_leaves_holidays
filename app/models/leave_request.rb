class LeaveRequest < ActiveRecord::Base
  unloadable
  include LeavesHolidaysLogic
  
  belongs_to :user
  belongs_to :issue

  enum request_status: { pending: 0, processed: 1 }
  enum request_type: { am: 0, pm: 1, ampm: 2 }

  validates :from_date, date: true, presence: true
  validates :to_date, date: true, presence: true
  validates :user, presence: true
  validates :issue, presence: true
  validates :request_type, presence: true
  validates :request_status, presence: true


   validate :validate_date_period
   validate :validate_issue

  attr_accessor :leave_time_am, :leave_time_pm
  attr_accessible :from_date, :to_date, :leave_time_am, :leave_time_pm, :issue_id, :comments, :user_id

	private

	def validate_date_period
		if to_date != nil && from_date != nil && to_date < from_date
			errors.add(:base,"The Leave period entered is invalid")
		end
	end

	def validate_issue
		if issue_id != nil && !((issues_list.collect {|t| t.id }).include?( issue_id))
			errors.add(:issue, "is invalid")
		end
	end

	
end
