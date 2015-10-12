class RemoveDefaultVote < ActiveRecord::Migration
  # def change
  # 		change_column_default(:leave_votes, :vote, nil)
  # end

  def up
    change_column :leave_votes, :vote, :integer, default: nil
  end

  def down
    change_column :leave_votes, :vote, :integer, default: 0
  end
end