class AddCanCreateRequestLeavePreferences < ActiveRecord::Migration
  def change
      add_column :leave_preferences, :can_create_leave_requests, :boolean, :null => false, default: true
  end
end