class RemoveDefaultVote < ActiveRecord::Migration
  def change
  		change_column_default(:leave_votes, :vote, nil)
  end
end