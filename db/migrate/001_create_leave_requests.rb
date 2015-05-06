class CreateLeaveRequests < ActiveRecord::Migration
  def change
    create_table :leave_requests do |t|
    	t.column :from_date, :date, index: true, :null => false
    	t.column :to_date, :date, index: true, :null => false
    	t.column :comments, :text, :null => true
    	t.column :request_type, :integer, default: 0, index: true, :null => false
    	t.column :request_status, :integer, default: 0, index: true, :null => false
    	t.belongs_to :user, index: true, :null => false
    	t.belongs_to :issue, index: true, :null => false
    end
  end
end
