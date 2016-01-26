class CreateLeaveReasonRules < ActiveRecord::Migration
  def change
    create_table :leave_reason_rules do |t|
      t.references :leave_management_rule, index: true, :null => false
      t.references :issue, index: true, :null => false
    end
  end
end