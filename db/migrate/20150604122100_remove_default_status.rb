class RemoveDefaultStatus < ActiveRecord::Migration
  # def change
  # 		change_column_default(:leave_statuses, :acceptance_status, nil)
  # end

  def up
    change_column :leave_statuses, :acceptance_status, :integer, default: nil
  end

  def down
    change_column :leave_statuses, :acceptance_status, :integer, default: 0
  end
end


