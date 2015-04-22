class CreateLeaveStatuses < ActiveRecord::Migration
  def change
    create_table :leave_statuses do |t|
    	t.column :processed_date, :date
    	t.column :acceptance_status, :integer, default: 0
    	t.column :comments, :text
    	t.belongs_to :user, index: true
    	t.belongs_to :leave_request, index: true
    end
  end
end
