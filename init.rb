require 'redmine'
require 'redmine_leaves_holidays'
include CalendarsHelper

Redmine::Plugin.register :redmine_leaves_holidays do
  name 'Redmine Leave Holidays plugin'
  author 'Stephane EVRARD'
  description 'A Leave Management System for redmine (Calendar, Mail notifications, Role based, Cross Project)'
  version '0.2'
  requires_redmine :version_or_higher => "3.0.0"

  settings :default => {:default_tracker_id => "1", :default_project_id => "1", :default_working_hours_week => "37",
  						:annual_leave_days_max => "25"}, :partial => "settings/leaves_holidays_settings"

project_module :leave_management do
  permission :view_all_leave_requests, { :leaves_requests => :view_all }
  permission :manage_leave_requests, { :leaves_requests => :manage }
  permission :consult_leave_requests, { :leaves_requests => :vote }
  permission :manage_user_leave_preferences, { :leaves_requests => :manage_user_prefs }
  permission :create_leave_requests, { :leaves_requests => :create, :leave_timelines => :show_project }
  permission :manage_leave_management_rules, { :leave_management_rules => [:edit, :update, :index, :show_metrics], :leave_administrators => [:edit]}
end
  menu :account_menu, :redmine_leaves_holidays, { :controller => 'leave_requests', :action => 'index' }, :caption => 'Leave/Holidays', :if => Proc.new {LeavesHolidaysLogic.has_create_rights(User.current) || LeavesHolidaysLogic.has_view_all_rights(User.current) }

  menu :project_menu, :redmine_leaves_holidays, { :controller => 'leave_timelines', :action => 'show_project'},
                              :caption => :tab_leaves_timeline,
                              :after => :gantt,
                              :param => :project_id

end

Rails.configuration.to_prepare do

  ActiveSupport::Inflector.inflections do |inflect|
    inflect.irregular 'actor_concerned', 'actors_concerned'
  end

  require 'holidays/core_extensions/date'
  class Date
    include Holidays::CoreExtensions::Date
  end
  
  Holidays.load_all
  require 'rufus/scheduler'

  leave_job = Rufus::Scheduler.new(:lockfile => ".leave-scheduler.lock")
  
  unless leave_job.down?
	leave_job.cron '30 0 * * *' do
		LeavesHolidaysTriggers::check_perform_users_renewal
        Rails.logger.info "Sheduler finished running RENEWAL_TRIGGER: #{Time.now}"
	end
  end
end

