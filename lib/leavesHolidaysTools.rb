class LeavesHolidaysTools
	include ActiveModel::Model
	include LeavesHolidaysLogic

	attr_accessor :from_date, :to_date, :issue_id, :comments, :half_day_choice

	validates :from_date, :date => true
	validates :to_date, :date => true


	validate :validate_date_period

	def issue_correct?
		Rails.logger.info "CALLED ISSUE CORRECT #{issues_list}"
	end
	
	private

	def validate_date_period
		if to_date < from_date
			errors.add :to_date, :greater_than_from_date
		end
	end

	

end