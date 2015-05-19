class CreateLeaveVotes < ActiveRecord::Migration
  def change
    create_table :leave_votes do |t|
    	t.column :vote, :integer, default: 0, index: true, :null => false
    	t.column :weight, :integer, default: 1
    	t.column :comments, :text
    	t.column :created_at, :datetime
        t.column :updated_at, :datetime

    	t.belongs_to :user, index: true
    	t.belongs_to :leave_request, index: true
    end
  end
end
