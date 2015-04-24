require 'redmine'
require 'LeavesHolidaysLogic'

Redmine::Plugin.register :redmine_leaves_holidays do
  name 'Redmine Leaves Holidays plugin'
  author 'Stephane EVRARD'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  settings :default => {:default_tracker_id => "1", :default_project_id => "1", :default_working_hours_week => "37",
  						:default_days_leaves_year => "25"}, :partial => "settings/leaves_holidays_settings"

  permission :manage_leaves_requests, { :leaves_requests => :manage }
end

# ActionDispatch::Callbacks.to_prepare do
# 	require 'redmine_leaves_holidays'
# end

require_dependency 'redmine_leaves_holidays/hooks'