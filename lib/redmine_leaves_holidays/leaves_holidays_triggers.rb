module LeavesHolidaysTriggers
	include LeavesHolidaysLogic
	include LeavesHolidaysDates

	# Checks renewal for any active user
	def self.check_perform_users_renewal(date = Date.today)
		users = User.all.active.under_contract.not_contractor.can_create_leave_request
		users.each do |user|
			if self.user_renew_contract?(user, date)
      			self.trigger_renew_contract_user(user, date)
    		end
		end
	end

	# Tells if a user contract should be renewed -> should report non taken leave
	def self.user_renew_contract?(user, date = Date.today)
    contract_end_date = user.contract_end_date
    return false if contract_end_date && contract_end_date < date
		# Get user contract start date
		contract_start_date = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date
		# Get user leave renewal date
    renewal_date = LeavesHolidaysLogic.user_params(user, :leave_renewal_date).to_date
		# Gets the last renewal date for user
		last_renewal = LeaveEvent.for_user(user.id).contract_renewal.last
		last_renewal_date = last_renewal.created_at.to_date if last_renewal != nil

		# Get the leave period associated with the given date
		period = LeavesHolidaysDates.get_leave_period(contract_start_date, renewal_date, date)
    previous_period = LeavesHolidaysDates.get_previous_leave_period(contract_start_date, renewal_date, date)

		# If the given date is actually the start of the leave period calculated
		# and if the last renewal date is different from the start period, return true
		return period[:start] == date && period[:start] != last_renewal_date && previous_period != nil
	end

	# Adds event entry
	# renews the contract for the given user (report of non taken leave days for new contract year)
	def self.trigger_renew_contract_user(user, date = Date.today)
    valid = true
    if user.has_valid_leave_region?
  		contract_start_date = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date
  		renewal_date = LeavesHolidaysLogic.user_params(user, :leave_renewal_date).to_date
  		last_renewal = LeaveEvent.for_user(user.id).contract_renewal.last

  		if last_renewal != nil
  			period = LeavesHolidaysDates.get_leave_period(contract_start_date, renewal_date, last_renewal.created_at.to_date)
  		else
  			period = LeavesHolidaysDates.get_previous_leave_period(contract_start_date, renewal_date, date)
  		end

      # remaining = LeavesHolidaysDates.total_leave_days_remaining(user, period[:start], period[:end])
      actual_days_max = user.actual_days_max(date)
      extra_leave_days = user.leave_preferences.extra_leave_days
      remaining = LeavesHolidaysDates.total_leave_days_remaining(user, period[:start], period[:end], actual_days_max, extra_leave_days)

      if remaining <= 0
      	user.leave_preferences.update(extra_leave_days: remaining)
      else
      	user.leave_preferences.update(pending_day_count: remaining, extra_leave_days: 0.0)
      end
    else
      valid = false
    end
      if valid
        str = "SYSTEM renewed leave period"
        event = "contract_renewal"
      else
        str = "SYSTEM ERROR invalid region while renewing conract"
        event = "region_error_invalid"
      end
      event = LeaveEvent.new(user_id: user.id, event_type: event, comments: str)
      event.event_data = user.leave_preferences.attributes
      event.save
	end

  def self.send_training_feedback_reminders(date = Date.today)

    start_search = date - 30
    end_search = date
    number_working_after_training_done = LeavesHolidaysLogic.get_training_feedback_days

    trainings_to_check = LeaveRequest.trainings.accepted.ended_between(start_search, end_search)
    leave_list = []
    trainings_to_check.each do |request|
      user = request.user
      leave_list << request if user.get_next_n_working_days(request.to_date, number_working_after_training_done) == date
    end

    leave_list.map(&:send_training_feedback_email)
  end
end