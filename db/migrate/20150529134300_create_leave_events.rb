class CreateLeaveEvents < ActiveRecord::Migration
  def change
    create_table :leave_events do |t|
        t.column :event_type, :integer, default: 0, :null => false
    	t.column :comments, :text
    	t.column :created_at, :datetime
        t.column :updated_at, :datetime

    	t.belongs_to :user, index: true
    end

    remove_column :leave_preferences, :triggered_at, :datetime
  end
end
