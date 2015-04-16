module RedmineLeavesHolidays
	Class Setting
		def self.default_tracker_id
	      ::Setting.plugin_redmine_leaves_holidays[:default_tracker_id]
	    end
	end
end