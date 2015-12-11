class CreateLeaveAdministrators < ActiveRecord::Migration
  def change
    create_table :leave_administrators do |t|
      t.belongs_to :project, index: true
      t.belongs_to :user, index: true
    end
  end
end