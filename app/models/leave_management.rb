class LeaveManagement < ActiveRecord::Base
  unloadable

  belongs_to :role_request, :class_name => "Role" #Role who makes the leave request
  enum action: { notified: 0, consulted: 1, managed: 2 } #Action to make
  belongs_to :role_action, :class_name => "Role" #Role who makes / gets (notification) the action associated
  belongs_to :project


end