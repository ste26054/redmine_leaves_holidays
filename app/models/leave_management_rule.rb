class LeaveManagementRule < ActiveRecord::Base
  unloadable

  belongs_to :sender, polymorphic: true # Sender can be a Role or a User
  belongs_to :receiver , polymorphic: true # receiver can be a Role or a User

  # Sender [notifies, is consulted by, is managed by] Receiver
  enum action: { notifies_approved: 0, is_consulted_by: 1, is_managed_by: 2 } #Action to make
  belongs_to :project


end