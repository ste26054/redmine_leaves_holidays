module LeavesHolidaysTriggers
	include LeavesHolidaysLogic
	include LeavesHolidaysDates


	def self.user_renew_contract?(user)
		user_prefs = LeavePreference.for_user(user.id)
		contract_date = nil
		if user_prefs.empty?
			contract_date = RedmineLeavesHolidays::Setting.defaults_settings(:contract_start_date).to_date
		else
			contract_date = user_prefs.contract_start_date
		end
		last_renewal_date = LeaveEvent.for_user(user.id).contract_renewal.last
		last_renewal_date = contract_date if last_renewal_date == nil

		return (Date.today.day == last_renewal_date.day) && (Date.today.month == last_renewal_date.month) && ((Date.today - last_renewal_date).day >= 1.year)
	end
end