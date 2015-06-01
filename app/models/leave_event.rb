class LeaveEvent < ActiveRecord::Base
  unloadable

  default_scope { order(updated_at: :asc) }

  enum event_type: { contract_renewal: 0, leave_notification: 1 }

  validates :event_type, presence: true

  belongs_to :user

  attr_accessible :user_id, :event_type, :comments
  
  scope :for_user, ->(uid) { where(user_id: uid) }

  scope :contract_renewal, -> { where(event_type: "0") }
end