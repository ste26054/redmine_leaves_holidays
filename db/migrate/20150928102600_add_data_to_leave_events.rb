class AddDataToLeaveEvents < ActiveRecord::Migration
  def change
      add_column :leave_events, :event_data, :text
  end
end