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
		months = self.months_between(from, to + 1.day)
		
		remaining = LeavesHolidaysLogic.user_params(user, :default_days_leaves_months) * months.to_f
		remaining = self.floor_to_nearest_half_day(remaining)
		remaining += LeavesHolidaysLogic.user_params(user, :extra_leave_days).to_f

		leaves_list = LeaveRequest.for_user(user.id).accepted.overlaps(from, to).not_informational
		leaves_list.find_each do |l|
			unless l.from_date < from
				#If a leave overlaps the period, take all of the leave days in the current period
				#remaining -= l.actual_leave_days
				#If a leace overlaps the period, take only the part inside the period
				remaining -= l.actual_leave_days_within(from, to)
			end
		end
		return remaining
	end



	# leave days taken by for user starting from the users's contract day and month
	def self.total_leave_days_taken(user, from, to)
		prefs = LeavePreference.where(user_id: user.id).first
		total = 0.0

		leaves_list = LeaveRequest.for_user(user.id).accepted.overlaps(from, to).not_informational
		leaves_list.find_each do |l|
			total += l.actual_leave_days_within(from, to)
		end
		return total
	end

	
	#contract_start_date = 01/01/2014, renewal_date = 01/06, current_date = 05/01/2014 -> res[:start] = 01/01/2014, res[:end] = 31/05/2014
	#contract_start_date = 01/01/2013, renewal_date = 01/06, current_date = 05/01/2014 -> res[:start] = 01/06/2013, res[:end] = 31/05/2014
	def self.get_contract_period(contract_start_date, renewal_date, current_date = Date.today)

		renewal_period = {}

		renewal_period[:start] = renewal_date + (current_date.year - renewal_date.year).year

		if renewal_period[:start] > current_date
			renewal_period[:start] = renewal_period[:start] - 1.year
		end

		renewal_period[:end] = renewal_period[:start] + 1.year - 1.day

		res = {}
		if contract_start_date < renewal_period[:start]
			res = renewal_period
		else
			res[:start] = contract_start_date
			res[:end] = renewal_period[:end]
		end

		return res
	end

	def self.get_days(arg, user)
	    res = {}

	    contract_start = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date
	    renewal_date = LeavesHolidaysLogic.user_params(user, :leave_renewal_date).to_date
	    
	    period = self.get_contract_period(contract_start, renewal_date)

	    case arg
	    when :remaining
	      res[:start] = period[:start]
	      res[:end] = period[:end]
	      res[:result] = self.total_leave_days_remaining(user, res[:start], res[:end])
	      return res
	    when :accumulated
	      res[:start] = period[:start]
	      res[:end] = Date.today
	      res[:result] = self.total_leave_days_accumulated(user, res[:start], res[:end])
	      return res
	    when :taken
	      res[:start] = period[:start]
	      res[:end] = period[:end]
	      res[:result] = self.total_leave_days_taken(user, res[:start], res[:end])
	      return res
	    else
	      return res
	    end
	end

end