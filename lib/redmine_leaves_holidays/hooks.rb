module LeavesHolidays
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_my_account_contextual,
              :partial => 'hooks/leaves_holidays/view_my_account_contextual'
  end
end
