class LeavesHolidaysTools
	include ActiveModel::Model
	include LeavesHolidaysLogic

	attr_accessor :leave_from, :leave_to, :issue_id #, :comments, :half_day_choice

	validates :leave_from, :presence => true
	validates :leave_to, :presence => true
	validates :issue_id, :presence => true

	validate :validate_date_period

	private

	def validate_date_period

		begin
			from = Date.parse(leave_from)
			to = Date.parse(leave_to)

			if to < from
				errors.add :leave_to, :greater_than_leave_from
			end
		rescue ArgumentError
			errors.add(:leave_from, "Invalid date")
			errors.add(:leave_to, "Invalid date")
		end

		
	end
	

end