class AddCommentsLeavePreferences < ActiveRecord::Migration
  def change
  		add_column :leave_preferences, :annual_max_comments, :text
  		add_column :leave_preferences, :triggered_at, :datetime
  end
end