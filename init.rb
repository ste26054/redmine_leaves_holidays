require 'redmine'

Redmine::Plugin.register :redmine_leaves_holidays do
  name 'Redmine Leaves Holidays plugin'
  author 'Stephane EVRARD'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  settings :default => {:default_tracker_id => "1"}, :partial => "settings/leaves_holidays_settings"
end

ActionDispatch::Callbacks.to_prepare do
	require_dependency 'project'
	require_dependency 'principal'
	require_dependency 'user'

	MyController.send(:include,  LeavesHolidaysPlugin::MyControllerPatch)
	# User.send(:include,  LeavesHolidaysPlugin::UsersLeavesPatch)
	# UsersController.send(:include,  LeavesHolidaysPlugin::UsersControllerPatch)
	# UsersHelper.send(:include,  LeavesHolidaysPlugin::UsersHelperPatch)
end

require 'leaves_holidays'

require "my_controller_patch.rb"
# require "users_leaves_patch.rb"
# require "users_controller_patch.rb"
# require "users_helper_leaves_patch.rb"
# hooks
require_dependency 'redmine_leaves_holidays/hooks'