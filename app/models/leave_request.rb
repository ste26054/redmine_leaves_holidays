class LeaveRequest < ActiveRecord::Base
  unloadable
  
  belongs_to :user
  belongs_to :issue

  enum status: { pending: 0, processed: 1 }
  enum type: { am: 0, pm: 1, ampm: 2 }
end
