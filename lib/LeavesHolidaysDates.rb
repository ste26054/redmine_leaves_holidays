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
	def self.total_leave_days_accumulated(user, from, to)
		prefs = LeavePreference.where(user_id: user.id).first
		total = 0.0
		total += prefs.extra_leave_days if prefs != nil
		months = self.months_between(from, to) % 12
		leave_days = LeavesHolidaysLogic.user_params(user, :default_days_leaves_months) * months.to_f
		return self.floor_to_nearest_half_day(leave_days) + total
	end

	def self.total_leave_days_remaining(user, from, to)
		remaining = LeavesHolidaysLogic.user_params(user, :annual_leave_days_max).to_f
		remaining += LeavesHolidaysLogic.user_params(user, :extra_leave_days).to_f
		leaves_list = LeaveRequest.for_user(user.id).accepted.overlaps(from, to).not_informational
		leaves_list.find_each do |l|
			unless l.from_date < from
				remaining -= l.actual_leave_days
			end
		end
		return remaining
	end

	def self.total_leave_days_remaining_v2(user, from, to)
		months = self.months_between(from, to + 1.day)

		remaining = LeavesHolidaysLogic.user_params(user, :default_days_leaves_months) * months.to_f
		remaining = self.floor_to_nearest_half_day(remaining)
		remaining += LeavesHolidaysLogic.user_params(user, :extra_leave_days).to_f

		leaves_list = LeaveRequest.for_user(user.id).accepted.overlaps(from, to).not_informational
		leaves_list.find_each do |l|
			unless l.from_date < from
				remaining -= l.actual_leave_days
			end
		end
		return remaining
	end



	# leave days taken by for user starting from the users's contract day and month, 
	def self.total_leave_days_taken(user, from, to)
		prefs = LeavePreference.where(user_id: user.id).first
		total = 0.0

		leaves_list = LeaveRequest.for_user(user.id).accepted.overlaps(from, to).not_informational
		leaves_list.find_each do |l|
			total += l.actual_leave_days_within(from, to)
		end
		return total
	end

	def self.get_contract_period(contract_date, date = Date.today)
		res = {}
		today = date

		res[:start] = contract_date + (today.year - contract_date.year).year

		if res[:start] > today
			res[:start] = res[:start] - 1.year
		end

		res[:end] = res[:start] + 1.year - 1.day

		return res
	end

	def self.get_contract_period_v2(contract_date, renewal_date, date = Date.today)
		renewal_period = self.get_contract_period(renewal_date, date)
		res = {}
		if contract_date < renewal_period[:start]
			res = renewal_period
		else
			res[:start] = contract_date
			res[:end] = renewal_period[:end]
		end

		return res
	end

end