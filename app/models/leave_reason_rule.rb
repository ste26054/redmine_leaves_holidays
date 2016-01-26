class LeaveReasonRule < ActiveRecord::Base
  unloadable

  belongs_to :leave_management_rule
  belongs_to :issue

  validates :leave_management_rule, presence: true
  validates :issue, presence: true

end