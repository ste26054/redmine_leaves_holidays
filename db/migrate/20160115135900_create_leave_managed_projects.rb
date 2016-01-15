class CreateLeaveManagedProjects < ActiveRecord::Migration
  def change
    create_table :leave_managed_projects do |t|
      t.belongs_to :project, index: true
      t.belongs_to :user, index: true
    end
  end
end