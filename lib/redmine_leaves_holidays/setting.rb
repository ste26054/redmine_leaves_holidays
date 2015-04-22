module RedmineLeavesHolidays
	class Setting
		def self.default_tracker_id
	      ::Setting.plugin_redmine_leaves_holidays[:default_tracker_id]
	    end

	    def self.default_project_id
	      ::Setting.plugin_redmine_leaves_holidays[:default_project_id]
	    end

	    def self.working_hours_week
	    	::Setting.plugin_redmine_leaves_holidays[:default_working_hours_week]
	    end

	    def self.days_leaves_year
	    	::Setting.plugin_redmine_leaves_holidays[:default_days_leaves_year]
	    end
	end
end