module LeavesHolidaysDates
	include LeavesHolidaysLogic

	def self.months_between(date1, date2)
		# Thanks http://stackoverflow.com/questions/9428605/find-number-of-months-between-two-dates-in-ruby-on-rails
		return (date2.year - date1.year) * 12 + date2.month - date1.month - (date2.day >= date1.day ? 0 : 1)
	end

	def self.average_days_per_year
		return ((365 * 3 + 366) / 4.0)
	end

	def self.average_days_per_months
		return self.average_days_per_year / 12.0
	end	

	# Used to compute a correct number of leave days
	def self.floor_to_nearest_half_day(n)
		return ((n.to_f * (1 / 0.5)).floor) / (1 / 0.5)
	end

	# Leave days accumulated for the year starting with the user's contract day and month, ignoring leaves taken
	def self.total_leave_days_available(user, date)
		prefs = LeavePreference.where(user_id: user.id).first
		total = 0.0
		total += prefs.extra_leave_days if prefs != nil
		contract_start_date = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date
		months = self.months_between(contract_start_date, date) % 12
		#months = ((((date - contract_start_date).to_i) % self.average_days_per_year) / self.average_days_per_months).floor
		leave_days = LeavesHolidaysLogic.user_params(user, :default_days_leaves_months) * months.to_f
		return self.floor_to_nearest_half_day(leave_days) + total
	end

	# leave days taken by for user starting from the users's contract day and month, 
	def self.total_leave_days_taken(user, date)
		prefs = LeavePreference.where(user_id: user.id).first
	end

end