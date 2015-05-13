class AddNewLeavePreferences < ActiveRecord::Migration
  def change
  		add_column :leave_preferences, :contract_start_date, :date, :null => false
  		add_column :leave_preferences, :extra_leave_days, :float, :null => false
  end
end