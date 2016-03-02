class CreateLeaveRules < ActiveRecord::Migration
  def change
    create_table :leave_rules do |t|
      t.references :issue, index: true, :null => false
    end
  end
end