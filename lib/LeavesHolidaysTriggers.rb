module LeavesHolidaysTriggers
	include LeavesHolidaysLogic
	include LeavesHolidaysDates

	def self.check_perform_users_renewal
		users = User.where(status: 1)
		users.each do |user|
			if self.user_renew_contract?(user)
      			self.trigger_renew_contract_user(user)
    		end
		end
	end

	def self.user_renew_contract?(user, date = Date.today)

		user_prefs = LeavePreference.for_user(user.id)
		contract_date = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date
		
		last_renewal = LeaveEvent.for_user(user.id).contract_renewal.last
		last_renewal_date = last_renewal.created_at.to_date if last_renewal != nil

		period = LeavesHolidaysDates.get_contract_period(contract_date)

		return period[:start] == date && period[:start] != last_renewal_date
	end

	# Adds event entry
	# renews the contract for the given user (report of non taken leave days for new contract year)
	def self.trigger_renew_contract_user(user)
		contract_date = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date

		last_renewal = LeaveEvent.for_user(user.id).contract_renewal.last

		if last_renewal != nil
			last_renewal_date = last_renewal.created_at.to_date
		else
			last_renewal_date = contract_date
		end

		period = LeavesHolidaysDates.get_contract_period(contract_date, last_renewal_date)

	    remaining = LeavesHolidaysDates.total_leave_days_remaining(user, period[:start], period[:end])

	    preference = LeavePreference.find_by(user_id: user.id)

	    if preference == nil
	    	preference = LeavesHolidaysLogic.retrieve_leave_preferences(user)
	    end

	    preference.update(extra_leave_days: remaining, annual_max_comments: "System reported #{remaining} on #{Date.today}")

	    event = LeaveEvent.new(user_id: user.id, event_type: "contract_renewal", comments: "extra: #{remaining}")
	    event.save
	end
end