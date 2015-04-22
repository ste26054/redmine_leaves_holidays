class LeaveStatus < ActiveRecord::Base
  unloadable
  
  belongs_to :user
  belongs_to :leave_request

  enum acceptance_status: { rejected: 0, accepted: 1 }
end
