module LeavesHolidaysDates
	include LeavesHolidaysLogic
	include Redmine::Utils::DateCalculation

	def self.months_between(date1, date2)
		# Thanks http://stackoverflow.com/questions/9428605/find-number-of-months-between-two-dates-in-ruby-on-rails
		return (date2.year - date1.year) * 12 + date2.month - date1.month - (date2.day >= date1.day ? 0 : 1)
	end

	# returns the floating number of months between two dates. Takes into account the fraction of month worked for the start / end dates
	def self.float_months_between(start_date, end_date)
		days_month_start = start_date.end_of_month.day
		days_month_end = end_date.end_of_month.day

		fraction_of_start_month = (days_month_start - start_date.day + 1).to_f / days_month_start.to_f
		fraction_of_end_month = end_date.day.to_f / days_month_end.to_f
		return ((end_date.year - start_date.year) * 12 + end_date.month - start_date.month + fraction_of_start_month + fraction_of_end_month - 1.0).round(2)
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
	# Checked 22/10/2015 OK
	def self.total_leave_days_accumulated(from, to, annual_leave_days_max, contract_start_date, contract_end_date = nil)
		#contract_start_date = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date
		#contract_end_date = user.contract_end_date

		return 0.0 if to < contract_start_date #ok
		from = contract_start_date if from < contract_start_date #ok
		to = contract_end_date if contract_end_date && to > contract_end_date #ok

		leave_days = (annual_leave_days_max.to_f / 12.0) * self.float_months_between(from, to)
		return self.ceil_to_nearest_half_day(leave_days)
	end

	# Gives the actual leave entitlement for the user if he does not work a full year (new comer, contract ended)
	#Checked 08/01/2016 OK
	def self.actual_days_max(from, to, annual_leave_days_max, contract_start_date, contract_end_date = nil)

		return 0.0 if to < contract_start_date #ok
		from = contract_start_date if from < contract_start_date #ok
		to = contract_end_date if contract_end_date && to > contract_end_date #ok

		holidays_per_month = annual_leave_days_max / 12.0 


		holiday_entitlement = holidays_per_month * self.float_months_between(from, to)#.ceil

		if holiday_entitlement < annual_leave_days_max
			return self.ceil_to_nearest_half_day(holiday_entitlement)
		else
			return annual_leave_days_max
		end

	end

	def self.total_leave_days_remaining(user, from, to, actual_days_max, extra_leave_days, include_pending = true)
		# lp = user.leave_preferences
		# remaining = self.actual_days_max(from, to, lp.annual_leave_days_max, lp.contract_start_date, lp.contract_end_date)
		remaining = actual_days_max

		# Add (or remove) extra leave days if there are
		# remaining += LeavesHolidaysLogic.user_params(user, :extra_leave_days).to_f
		remaining += extra_leave_days

		if include_pending
			leaves_list = LeaveRequest.for_user(user.id).pending_or_accepted.overlaps(from, to).not_informational
		else
			leaves_list = LeaveRequest.for_user(user.id).accepted.overlaps(from, to).not_informational
		end

		leaves_list.find_each do |l|
			unless l.from_date < from
				#If a leave overlaps the period, take all of the leave days in the current period
				remaining -= l.actual_leave_days
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
	def self.get_leave_period(contract_start_date, leave_renewal_date, current_date = Date.today, force_full_year = false, contract_end_date = nil)
		# If current date before contract start date, set it to contract start date
		current_date = contract_start_date if current_date < contract_start_date

		# If there is a contract end date, and current date is after the end of the contract, set it to contract end date
		current_date = contract_end_date if contract_end_date && current_date > contract_end_date

		renewal_period = {}

		# Set beginning of renewal period: take renewal day/month, then /year of current date
		renewal_period[:start] = leave_renewal_date + (current_date.year - leave_renewal_date.year).year

		# If beginning of renewal period is after the current date, set it 1 year before
		if renewal_period[:start] > current_date
			renewal_period[:start] = renewal_period[:start] - 1.year
		end

		# Make end of renewal period 1 year - 1 day before
		renewal_period[:end] = renewal_period[:start] + 1.year - 1.day

		return renewal_period if force_full_year
		
		# Cases for not full years
		res = {}
		if (contract_start_date < renewal_period[:start])
			res = renewal_period
		else
			res[:start] = contract_start_date
			res[:end] = renewal_period[:end]
		end

		if contract_end_date && contract_end_date < renewal_period[:end]
			res[:end] = contract_end_date
		end

		return res
	end

	def self.get_previous_leave_period(contract_start_date, leave_renewal_date, current_date = Date.today, force_full_year = false, contract_end_date = nil)
		current_leave_period = self.get_leave_period(contract_start_date, leave_renewal_date, current_date, force_full_year, contract_end_date)
		return nil if current_leave_period[:start] - 1.day < contract_start_date
		return self.get_leave_period(contract_start_date, leave_renewal_date, current_leave_period[:start] - 1.day, force_full_year)
	end

	def self.get_leave_period_to_date(start_date, end_date, current_date = Date.today)
		period = {}

		period[:start] = start_date
		period[:end] = end_date

		if current_date >= start_date && current_date <= period[:end]
			period[:end] = current_date
			return period
		end
		if current_date < start_date
			period[:end] = start_date
			return period
		end
		if current_date > period[:end]
			return period
		end
	end

end