class AddLeaveRenewalDatePrefs < ActiveRecord::Migration
  def change
  		add_column :leave_preferences, :leave_renewal_date, :date, :null => false
  end
end