require 'redmine'

Redmine::Plugin.register :redmine_leaves_holidays do
  name 'Redmine Leaves Holidays plugin'
  author 'Stephane EVRARD'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  settings :default => {:default_tracker_id => "1"}, :partial => "settings/leaves_holidays_settings"
end

# hooks
require_dependency 'redmine_leaves_holidays/hooks'