class LeaveExceptionRule < ActiveRecord::Base
  unloadable

  belongs_to :leave_management_rule
  belongs_to :user

  enum actor_concerned: { sender: 0, receiver: 1 } #Action to make


end