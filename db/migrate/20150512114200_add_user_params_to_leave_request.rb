class AddUserParamsToLeaveRequest < ActiveRecord::Migration
  def change
  		add_column :leave_requests, :weekly_working_hours, :float, :null => false
  		add_column :leave_requests, :annual_leave_days_max, :float, :null => false
  end
end