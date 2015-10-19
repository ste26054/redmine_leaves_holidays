class DropLeaveManagements < ActiveRecord::Migration
  def up
    drop_table :leave_managements
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end