require 'redmine'

Redmine::Plugin.register :redmine_leaves_holidays do
  name 'Redmine Leaves Holidays plugin'
  author 'Stephane EVRARD'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  settings :default => {:default_tracker_id => "1", :default_project_id => "1", :default_working_hours_day => "7.4"}, :partial => "settings/leaves_holidays_settings"
end

# ActionDispatch::Callbacks.to_prepare do
# 	require 'redmine_leaves_holidays'
# end

require_dependency 'redmine_leaves_holidays/hooks'