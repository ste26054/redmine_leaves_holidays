class CreateLeaveExceptionRules < ActiveRecord::Migration
  def change
    create_table :leave_exception_rules do |t|
      t.references :leave_management_rule, index: true, :null => false
      t.column :actor_concerned, :integer, :null => false
      t.references :user, index: true, :null => false
    end
  end
end