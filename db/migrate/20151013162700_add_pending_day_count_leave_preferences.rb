class AddPendingDayCountLeavePreferences < ActiveRecord::Migration
  def change
      add_column :leave_preferences, :pending_day_count, :float, default: 0
  end
end