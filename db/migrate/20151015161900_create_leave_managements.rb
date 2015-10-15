class CreateLeaveManagements < ActiveRecord::Migration
  def change
    create_table :leave_managements do |t|
      t.references :role_request, index: true, :null => false
      t.column :action, :integer, default: 0, :null => false
      t.references :role_action, index: true, :null => false
      t.references :project, index: true, :null => false
    end
  end
end