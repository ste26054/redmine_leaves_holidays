class AddPercentageAllocLeavePreferences < ActiveRecord::Migration
  def change
      add_column :leave_preferences, :overall_percent_alloc, :integer, :null => false, :default => 100
  end
end