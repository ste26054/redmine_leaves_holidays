module RedmineLeavesHolidays
	class Setting

	    def self.defaults_settings(arg)
	    	::Setting.plugin_redmine_leaves_holidays[arg]
	    end

	end
end