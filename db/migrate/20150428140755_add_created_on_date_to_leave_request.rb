class AddCreatedOnDateToLeaveRequest < ActiveRecord::Migration
  def change
  		add_column :leave_requests, :created_at, :datetime
  		add_column :leave_requests, :updated_at, :datetime
  		add_column :leave_statuses, :created_at, :datetime
  		add_column :leave_statuses, :updated_at, :datetime
  end
end
