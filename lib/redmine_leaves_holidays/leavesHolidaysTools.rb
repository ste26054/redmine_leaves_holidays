class LeavesHolidaysTools
	include ActiveModel::Model
	# include LeavesHolidaysHelper

	attr_accessor :from_date, :to_date, :issue_id, :comments, :half_day_choice

	validates :from_date, :date => true
	validates :to_date, :date => true


	validate :validate_date_period

	private

	def validate_date_period
		if to_date < from_date
			errors.add :to_date, :greater_than_from_date
		end
	end

	
	def issue_correct?
		Rails.logger.info " #{LeavesHolidaysHelper::issues_list}"
	end
	

end