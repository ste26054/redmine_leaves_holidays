Rails.configuration.to_prepare do

  require 'redmine_leaves_holidays/hooks'
  require 'redmine_leaves_holidays/setting'

  require 'redmine_leaves_holidays/leaves_holidays_extensions'

  require 'redmine_leaves_holidays/leaves_holidays_logic'
  require 'redmine_leaves_holidays/leaves_holidays_dates'
  require 'redmine_leaves_holidays/leaves_holidays_triggers'
  require 'redmine_leaves_holidays/leaves_holidays_managements'

  require 'redmine_leaves_holidays/helpers/timeline'

  require 'redmine_leaves_holidays/patches/mailer_patch'
  require 'redmine_leaves_holidays/patches/projects_helper_patch'
  require 'redmine_leaves_holidays/patches/user_patch'

end