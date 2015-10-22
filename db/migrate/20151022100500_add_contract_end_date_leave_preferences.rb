class AddContractEndDateLeavePreferences < ActiveRecord::Migration
  def change
      add_column :leave_preferences, :contract_end_date, :date, :null => true
  end
end