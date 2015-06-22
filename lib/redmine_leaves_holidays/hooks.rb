

module LeavesHolidaysPlugin
  class Hooks < Redmine::Hook::ViewListener
  	
    render_on :view_my_account_contextual,
              :partial => 'hooks/leaves_holidays/view_my_account_contextual'
    render_on :view_my_account_preferences,
              :partial => 'hooks/leaves_holidays/view_my_account_preferences'
    render_on :view_users_form_preferences,
              :partial => 'hooks/leaves_holidays/view_users_form_preferences'
  end
end
