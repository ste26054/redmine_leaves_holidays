class LeaveStatus < ActiveRecord::Base
  unloadable
  
  belongs_to :user
  belongs_to :leave_request

  enum acceptance_status: { rejected: 0, accepted: 1 }

  validates :processed_date, date: true, presence: true
  validates :user_id, presence: true
  validates :leave_request_id, presence: true
end
