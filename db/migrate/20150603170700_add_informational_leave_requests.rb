class AddInformationalLeaveRequests < ActiveRecord::Migration
  def change
  		add_column :leave_requests, :is_informational, :boolean, default: false
  end
end