class RemoveDefaultStatus < ActiveRecord::Migration
  def change
  		change_column_default(:leave_statuses, :acceptance_status, nil)
  end
end


