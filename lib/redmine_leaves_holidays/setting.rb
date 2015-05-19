module RedmineLeavesHolidays
	class Setting
		extend Redmine::Utils::DateCalculation
		

	    def self.defaults_settings(arg)
	    	case arg
	    	when :default_days_leaves_months
	    		return ::Setting.plugin_redmine_leaves_holidays[:annual_leave_days_max].to_f / 12.0
	    	when :is_contractor
	    		return false
	    	when :daily_working_hours
	    		return ::Setting.plugin_redmine_leaves_holidays[:weekly_working_hours].to_f / (7.0 - non_working_week_days.count )
	    	else
	    		return	::Setting.plugin_redmine_leaves_holidays[arg]	
	    	end
	    end


	end
end