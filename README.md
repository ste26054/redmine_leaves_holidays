# Redmine - Leave / Holidays Management plugin

The Leave Management plugin is a cross project plugin, which makes use of leave management rules created in each selected project to handle all of the leave request approval process.

=======
### Install

 - Go to `redmine/plugins` directory
 - `git clone` this repository
 - In `redmine` directory, run `bundle install` to install the required gems
 - Run db migrations `rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_leaves_holidays`
 - Restart Redmine
 - Go to Administration / Plugins and configure it


### Features

- Users can take full or half days leave, for a custom time period. They can specify if the leave is AM and/or PM
- Users can easily select a leave reason (Annual leave, sick leave...), and add a comment on their leave request
- Users can see how many days they can book as leave, on a dedicated dashboard
- Selected roles/users are notified when a user makes a leave request, or when a leave request status is updated
- Administrators can manage (add, remove) leave reasons
- Selected roles/users can manage (approve, reject), or be consulted for feedback (yes, no) on leave requests, depending on the user who made the leave request
- Selected roles/users can view all approved leave requests
- Selected roles/users can manage user preferences, generally or per user
  - User region, for computation of bank holidays
  - User weekly working hours
  - User maximum number of leave days per year
  - Leave renewal date for auto report of non taken leave days when this date is reached


### Permissions

   - manage_user_leave_preferences: Manage user leave details such as:
     - is allowed to create leave requests
     - leave entitlement
     - contract start / end date
     - extra days
     - ...
   - manage_leave_management_rules: Create / edit / delete leave management rules, at project level. This is used by the plugin to specify who is managed by who...
   - View_all_leave_requests: Allows to view all leave requests in the system, or get an email notification for any approved leave
 

 To be continued.
