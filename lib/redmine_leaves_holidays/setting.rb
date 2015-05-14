module RedmineLeavesHolidays
	class Setting

	    # def self.defaults_settings(arg)
	    # 	if arg == :default_days_leaves_months
	    # 		::Setting.plugin_redmine_leaves_holidays[:default_days_leaves_year].to_f / 12.0
	    # 	else
	    # 	else
	    # 		::Setting.plugin_redmine_leaves_holidays[arg]
	    # 	end
	    # end

	    def self.defaults_settings(arg)
	    	case arg
	    	when :default_days_leaves_months
	    		return ::Setting.plugin_redmine_leaves_holidays[:annual_leave_days_max].to_f / 12.0
	    	when :is_contractor
	    		return false
	    	else
	    		return	::Setting.plugin_redmine_leaves_holidays[arg]	
	    	end
	    end


	end
end