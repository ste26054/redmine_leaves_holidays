class AddRegionToLeaveRequest < ActiveRecord::Migration
  def change
  		add_column :leave_requests, :region, :string, :limit => 50, :null => false
  end
end
