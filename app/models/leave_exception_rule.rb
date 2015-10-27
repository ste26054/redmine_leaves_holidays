class LeaveExceptionRule < ActiveRecord::Base
  unloadable

  belongs_to :leave_management_rule
  belongs_to :user

  enum actor_concerned: { sender: 0, receiver: 1 } #Action to make

  validates :leave_management_rule, presence: true
  validates :user, presence: true
  validates :actor_concerned, presence: true, inclusion: { in: LeaveExceptionRule.actors_concerned.keys }


end