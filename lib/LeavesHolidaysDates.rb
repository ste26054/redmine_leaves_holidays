module LeavesHolidaysDates
	include LeavesHolidaysLogic
	include Redmine::Utils::DateCalculation

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
	# 1.2 -> 1.0, 1.5 -> 1.5, 1.6 -> 1.5, 1.99 -> 1.5...
	def self.floor_to_nearest_half_day(n)
		return ((n.to_f * (1 / 0.5)).floor) / (1 / 0.5)
	end

	# Used to compute a correct number of leave days
	# 1.2 -> 1.5, 1.5 -> 1.5, 1.6 -> 2.0, 1.99 -> 2.0...
	def self.ceil_to_nearest_half_day(n)
		return ((n.to_f * (1 / 0.5)).ceil) / (1 / 0.5)
	end

	# Leave days accumulated for the year starting with the user's contract day and month, ignoring leaves taken
	def self.total_leave_days_accumulated(user, from, to)
		prefs = LeavePreference.where(user_id: user.id).first
		total = 0.0
		#total += prefs.extra_leave_days if prefs != nil
		months = self.months_between(from, to) % 12
		leave_days = LeavesHolidaysLogic.user_params(user, :default_days_leaves_months) * months.to_f
		return self.ceil_to_nearest_half_day(leave_days) + total
	end

	def self.actual_days_max(user, from, to)
		annual_days_max = LeavesHolidaysLogic.user_params(user, :annual_leave_days_max).to_f

		working_days_count = user.working_days_count(from, to, false, false, true)

		working_weeks_count = working_days_count / 5.0 # there are 5 working days per week

		holidays_per_week = annual_days_max / 52.0 # 52 weeks a year

		holiday_entitlement = holidays_per_week * working_weeks_count

		if holiday_entitlement < annual_days_max
			return self.ceil_to_nearest_half_day(holiday_entitlement)
		else
			return annual_days_max
		end

	end

	def self.total_leave_days_remaining(user, from, to, include_pending = true)

		remaining = self.actual_days_max(user, from, to)

		# Add (or remove) extra leave days if there are
		remaining += LeavesHolidaysLogic.user_params(user, :extra_leave_days).to_f

		if include_pending
			leaves_list = LeaveRequest.for_user(user.id).pending_or_accepted.overlaps(from, to).not_informational
		else
			leaves_list = LeaveRequest.for_user(user.id).accepted.overlaps(from, to).not_informational
		end

		leaves_list.find_each do |l|
			unless l.from_date < from
				#If a leave overlaps the period, take all of the leave days in the current period
				remaining -= l.actual_leave_days
				#If a leace overlaps the period, take only the part inside the period
				#remaining -= l.actual_leave_days_within(from, to)
			end
		end
		return remaining
	end



	# leave days taken by for user starting from the users's contract day and month
	def self.total_leave_days_taken(user, from, to, include_pending = false)
		prefs = LeavePreference.where(user_id: user.id).first
		taken = 0.0

		if include_pending
			leaves_list = LeaveRequest.for_user(user.id).pending_or_accepted.overlaps(from, to).not_informational
		else
			leaves_list = LeaveRequest.for_user(user.id).accepted.overlaps(from, to).not_informational
		end

		leaves_list.find_each do |l|
			unless l.from_date < from
				taken += l.actual_leave_days#_within(from, to)
			end
		end
		return taken
	end

	
	#contract_start_date = 01/01/2014, leave_renewal_date = 01/06, current_date = 05/01/2014 -> res[:start] = 01/01/2014, res[:end] = 31/05/2014
	#contract_start_date = 01/01/2013, leave_renewal_date = 01/06, current_date = 05/01/2014 -> res[:start] = 01/06/2013, res[:end] = 31/05/2014
	def self.get_leave_period(contract_start_date, leave_renewal_date, current_date = Date.today, force_full_year = false)

		renewal_period = {}

		renewal_period[:start] = leave_renewal_date + (current_date.year - leave_renewal_date.year).year

		if renewal_period[:start] > current_date
			renewal_period[:start] = renewal_period[:start] - 1.year
		end

		renewal_period[:end] = renewal_period[:start] + 1.year - 1.day

		res = {}
		if (contract_start_date < renewal_period[:start] && !force_full_year) || force_full_year
			res = renewal_period
		else
			res[:start] = contract_start_date
			res[:end] = renewal_period[:end]
		end

		return res
	end

end