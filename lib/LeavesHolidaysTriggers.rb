module LeavesHolidaysTriggers
	include LeavesHolidaysLogic
	include LeavesHolidaysDates

	# Checks renewal for any active user
	def self.check_perform_users_renewal(date = Date.today)
		users = User.where(status: 1)
		users.each do |user|
			if self.user_renew_contract?(user, date)
      			self.trigger_renew_contract_user(user)
    		end
		end
	end

	# Tells if a user contract should be renewed -> should report non taken leave
	def self.user_renew_contract?(user, date = Date.today)
		contract_date = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date
    	renewal_date = LeavesHolidaysLogic.user_params(user, :leave_renewal_date).to_date
		# Gets the last renewal date of leave for user
		last_renewal = LeaveEvent.for_user(user.id).contract_renewal.last
		last_renewal_date = last_renewal.created_at.to_date if last_renewal != nil

		period = LeavesHolidaysDates.get_contract_period_v2(contract_date, renewal_date)

		# If the date is the same as the starting period and the contract was not yet renewed, return true
		return period[:start] == date && period[:start] != last_renewal_date
	end

	# Adds event entry
	# renews the contract for the given user (report of non taken leave days for new contract year)
	def self.trigger_renew_contract_user(user)
		contract_date = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date
		renewal_date = LeavesHolidaysLogic.user_params(user, :leave_renewal_date).to_date
		last_renewal = LeaveEvent.for_user(user.id).contract_renewal.last

		if last_renewal != nil
			last_renewal_date = last_renewal.created_at.to_date
		else
			last_renewal_date = contract_date
		end

		period = LeavesHolidaysDates.get_contract_period_v2(contract_date, renewal_date, last_renewal_date)

	    remaining = LeavesHolidaysDates.total_leave_days_remaining_v2(user, period[:start], period[:end])

	    preference = LeavePreference.find_by(user_id: user.id)

	    if preference == nil
	    	preference = LeavesHolidaysLogic.retrieve_leave_preferences(user)
	    end

	    preference.update(extra_leave_days: remaining, annual_max_comments: "System reported #{remaining} on #{Date.today}")

	    event = LeaveEvent.new(user_id: user.id, event_type: "contract_renewal", comments: "extra: #{remaining}")
	    event.save
	end
end