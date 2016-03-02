class CreateCustomFieldsLeaveRules < ActiveRecord::Migration
  def change
    create_table :custom_fields_leave_rules, :id => false, :force => true do |t|
      t.column :custom_field_id, :integer, :default => 0, :null => false, index: true
      t.column :leave_rule_id, :integer, :default => 0, :null => false, index: true
    end
  end
end