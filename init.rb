require 'redmine'
require 'LeavesHolidaysExtensions'
require 'LeavesHolidaysLogic'
require 'LeavesHolidaysDates'
require 'LeavesHolidaysTriggers'


Redmine::Plugin.register :redmine_leaves_holidays do
  name 'Redmine Leaves Holidays plugin'
  author 'Stephane EVRARD'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  settings :default => {:default_tracker_id => "1", :default_project_id => "1", :default_working_hours_week => "37",
  						:annual_leave_days_max => "25"}, :partial => "settings/leaves_holidays_settings"

  permission :view_all_leaves_requests, { :leaves_requests => :view_all }
  permission :manage_leaves_requests, { :leaves_requests => :manage }
  permission :vote_leaves_requests, { :leaves_requests => :vote }
  permission :manage_user_leaves_preferences, { :leaves_requests => :manage_user_prefs }

  menu :account_menu, :redmine_leaves_holidays, { :controller => 'leave_requests', :action => 'index' }, :caption => 'Leave/Holidays'
end

require_dependency 'redmine_leaves_holidays/hooks'

Rails.configuration.to_prepare do
  require 'rufus/scheduler'
  # job = Rufus::Scheduler.singleton.every '10s' do
  #   Rails.logger.info "SCHEDULER: time flies, it's now #{Time.now}"
  # end
end