class CreateLeaveManagementRules < ActiveRecord::Migration
  def change
    create_table :leave_management_rules do |t|
      t.references :sender, polymorphic: true, index: true
      t.column :action, :integer, default: 0, :null => false
      t.references :receiver, polymorphic: true, index: true
      t.references :project, index: true, :null => false
    end
  end
end