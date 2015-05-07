class CreateLeavePreferences < ActiveRecord::Migration
  def change
    create_table :leave_preferences do |t|
        t.column :weekly_working_hours, :float, :null => false
        t.column :annual_leave_days_max, :float, :null => false
        t.column :region, :string, :limit => 50, :null => false
        t.column :created_at, :datetime
        t.column :updated_at, :datetime
    	t.belongs_to :user, index: true, :null => false
    end
  end
end
