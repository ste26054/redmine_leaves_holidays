class AddContractorLeavePreferences < ActiveRecord::Migration
  def change
  		add_column :leave_preferences, :is_contractor, :boolean, default: false
  end
end