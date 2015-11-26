class LeaveExceptionRule < ActiveRecord::Base
  unloadable

  belongs_to :leave_management_rule
  belongs_to :user

  enum actor_concerned: { sender: 0, receiver: 1, backup_receiver: 2 } #Action to make

  validates :leave_management_rule, presence: true
  validates :user, presence: true
  validates :actor_concerned, presence: true, inclusion: { in: LeaveExceptionRule.actors_concerned.keys }

  validate :check_backup_receiver


  def check_backup_receiver
    if self.actor_concerned == 'backup_receiver' && !self.leave_management_rule.action == 'is_managed_by'
      errors.add(:actor_concerned, "Is invalid regarding the leave management rule action selected")
    end
  end
end