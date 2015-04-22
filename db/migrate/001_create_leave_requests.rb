class CreateLeaveRequests < ActiveRecord::Migration
  def change
    create_table :leave_requests do |t|
    	t.column :from_date, :date
    	t.column :to_date, :date
    	t.column :comments, :text
    	t.column :type, :integer, default: 0
    	t.column :status, :integer, default: 0
    	t.belongs_to :user, index: true
    	t.belongs_to :issue, index: true
    end
  end
end
