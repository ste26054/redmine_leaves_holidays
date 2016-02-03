module RedmineLeavesHolidays
	module Patches
		module  UserPatch
			def self.included(base) # :nodoc:

				base.send(:include, UserInstanceMethods)

		        base.class_eval do
		          unloadable # Send unloadable so it will not be unloaded in development
		          has_one :leave_preference, dependent: :destroy
		          has_many :leave_management_rules, as: :sender#, dependent: :destroy
		          has_many :leave_management_rules, as: :receiver#, dependent: :destroy
		          has_many :leave_administrators, dependent: :destroy
		          has_many :leave_events, dependent: :destroy
		          has_many :leave_exception_rules, dependent: :destroy
		          has_many :leave_managed_projects, dependent: :destroy

		          before_destroy :destroy_leave_management_rules

		          scope :with_leave_region, lambda { |arg|
		          	return nil if arg.blank?
						    arg = [*arg] or Array(arg)
						    args = arg.to_a & LeavesHolidaysLogic.get_region_list
						    ids = []
		          	uids_total = pluck(:id)
		          	users_with_lp = joins(:leave_preference).where(id: uids_total)
		          	uids_with_lp = users_with_lp.pluck(:id)
		          	uids_without_lp = uids_total - uids_with_lp

		          	ids << users_with_lp.joins(:leave_preference).where(:leave_preferences => {:region => args}).pluck(:id)

		          	ids << uids_without_lp if RedmineLeavesHolidays::Setting.defaults_settings(:region).in?(args)
		          	ids = ids.flatten.uniq

						    where(id: ids)
		          }

		          scope :contractor, lambda {
		          	joins(:leave_preference).where.not(leave_preferences: { id: nil }).where(:leave_preferences => {is_contractor: 1}) 
		          }

		          scope :cannot_create_leave_request, lambda {
		          	joins(:leave_preference).where.not(leave_preferences: { id: nil }).where(:leave_preferences => {can_create_leave_requests: 0}) 
		          }

							scope :can_create_leave_request, lambda {
								uids = pluck(:id)
		          	cannot_create_request_ids = joins(:leave_preference).where.not(leave_preferences: { id: nil }).where(leave_preferences: {can_create_leave_requests: 0}).pluck(:id)

		          	where(id: uids - cannot_create_request_ids)
		          }		         

		          scope :not_contractor, lambda {
		          	ids = []
		          	uids_total = pluck(:id)
		          	users_with_lp = joins(:leave_preference).where(id: uids_total)
		          	uids_with_lp = users_with_lp.pluck(:id)
		          	uids_without_lp = uids_total - uids_with_lp

		          	ids << users_with_lp.joins(:leave_preference).where(:leave_preferences => {:is_contractor => 0}).pluck(:id)
		          	ids << uids_without_lp
		          	ids = ids.flatten.uniq

						    where(id: ids)
		          }

		          # Returns all users in current scope that does not have a contract end date, or where contract end date > Today
		          scope :under_contract, lambda {
		          	ids = []
		          	uids_total = pluck(:id)
		          	uids_contracts_ended = joins(:leave_preference).where('leave_preferences.contract_end_date < ?', Date.today).pluck(:id)

		          	ids = uids_total - uids_contracts_ended
		          	
						    where(id: ids)
		          }

		          def destroy_leave_management_rules
		          	as_sender = LeaveManagementRule.where(sender: self)
		          	as_receiver = LeaveManagementRule.where(receiver: self)
		          	as_sender.destroy_all
		          	as_receiver.destroy_all
		          end
		          
		        end
		    end
		end

		module UserInstanceMethods
			include LeavesHolidaysLogic
			include LeavesCommonUserRole

			def leave_preferences
				return LeavePreference.find_by(user_id: self.id) || LeavesHolidaysLogic.get_default_leave_preferences(self)
			end

			def weekly_working_hours
				return self.leave_preferences.weekly_working_hours
			end

			def actual_weekly_working_hours
				lp = self.leave_preferences
				return (lp.weekly_working_hours * lp.overall_percent_alloc) / 100.0 
			end

			def leave_period(current_date = Date.today)
				lp = self.leave_preferences
				return LeavesHolidaysDates.get_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date, false, lp.contract_end_date)
			end
			
			def previous_leave_period(current_date = Date.today)
				lp = self.leave_preferences
				return LeavesHolidaysDates.get_previous_leave_period(lp.contract_start_date, lp.leave_renewal_date, current_date, false, lp.contract_end_date)
			end

			def leave_period_to_date(current_date = Date.today)
				lp = self.leave_preferences
				period = self.leave_period(current_date)
				if current_date >= period[:start] && current_date <= period[:end]
					period[:end] = current_date
					return period
				end
				if current_date < period[:start]
					period[:end] = period[:start]
					return period
				end
				if current_date > period[:end]
					return period
				end
			end

			def actual_days_max(current_date = Date.today)
				period = self.leave_period(current_date)
				lp = self.leave_preferences
				return LeavesHolidaysDates.actual_days_max(period[:start], period[:end], lp.annual_leave_days_max, lp.contract_start_date, lp.contract_end_date)
			end

			def days_remaining(current_date = Date.today)
				period = self.leave_period(current_date)
				lp = self.leave_preferences
				return LeavesHolidaysDates.total_leave_days_remaining(self, period[:start], period[:end], self.actual_days_max(current_date), lp.extra_leave_days)
			end

			def days_taken_accepted(current_date = Date.today)
				period = self.leave_period(current_date)
				return LeavesHolidaysDates.total_leave_days_taken(self, period[:start], period[:end])
			end

			def days_taken_total(current_date = Date.today)
				period = self.leave_period(current_date)
				return LeavesHolidaysDates.total_leave_days_taken(self, period[:start], period[:end], true)
			end

			def days_accumulated(current_date = Date.today)
				period = self.leave_period_to_date(current_date)
				lp = self.leave_preferences
				return LeavesHolidaysDates.total_leave_days_accumulated(period[:start], period[:end], lp.annual_leave_days_max, lp.contract_start_date, lp.contract_end_date)
			end

			def days_extra
				LeavesHolidaysLogic.user_params(self, :extra_leave_days).to_f
			end

			def css_background_color
    		Digest::MD5.hexdigest(self.login)[0..5]
  		end

		  def css_style
		    hex = css_background_color
		    rgb = hex.match(/(..)(..)(..)/).to_a.drop(1).map(&:hex)

		    #http://www.w3.org/TR/AERT#color-contrast
		    treshold = ((rgb[0] * 299) + (rgb[1] * 587) + (rgb[2] * 114)) / 1000

		    font_color = treshold > 125 ? "black" : "white"

		    return "background: \##{hex}; color: #{font_color};"
		  end

		  # used in redmine_workload_allocation plugin
		  def working_days_count(from_date, to_date, include_sat = false, include_sun = false, include_bank_holidays = false)
		  	dates_interval = (from_date..to_date).to_a

				user_region = LeavesHolidaysLogic.user_params(self, :region)

				if !include_bank_holidays
					bank_holidays_list = Holidays.between(from_date, to_date, user_region.to_sym, :observed).map{|k| k[:date]}
					dates_interval -= bank_holidays_list
				end

  			dates_interval.delete_if {|i| i.wday == 6 && !include_sat || #delete date from array if day of week is a saturday (6)
              			              i.wday == 0 && !include_sun } #delete date from array if day of week is a sunday (0)

    		return dates_interval.count
			end

			def is_contractor
				self.leave_preferences.is_contractor
			end

			def overall_percent_alloc
				self.leave_preferences.overall_percent_alloc
			end

			def contract_end_date
				self.leave_preferences.contract_end_date
			end

			# returns the list of projects where the user has a direct leave management rule set 
			def leave_managed_projects
				return LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by').map(&:project).uniq
			end

			# Set of "permissions" based on rules set in the different projects
			# A user can manage leave requests if he manages directly, is set as temporary backup, or is leave admin
			def can_manage_leave_requests
				LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'is_managed_by').any? || self.is_leave_admin?
			end

			def can_be_consulted_leave_requests
				LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'consults').any?
			end

			def can_be_notified_leave_requests
				LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'notifies_approved').any? || LeavesHolidaysLogic.has_view_all_rights(self)
			end

			def can_create_leave_requests
				lp = self.leave_preferences
				return lp.can_create_leave_requests
			end

			# Used in init.rb to check whether user has a link to the plugin displayed
			def has_leave_plugin_access?
				can_create_leave_requests || can_manage_leave_requests || can_be_consulted_leave_requests || can_be_notified_leave_requests
			end

			# If user is a leave admin, then he is managed
			def is_rule_managed_in_project?(project)
				LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by', project).any?
			end

			def is_rule_managed?
				LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by').any?
			end

			def is_managing?
				return LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'is_managed_by', [], [], true).any?
			end

			# Will tell if user leave requests will reach someone, cross project
			# If a user manages people, but is not managed by anyone, he is managed by the leave administrators
			# If a user is a contractor, and he notifies at least someone
			# If a user is explicitely managed by someone
			# If a user is a leave administrator, who can self approve his leave
			def is_notifying_people?
				return false unless self.can_create_leave_requests
				if self.is_contractor
					return self.notify_rules.any?
				else
					return true if self.can_self_approve_requests?
					if self.is_rule_managed?
						return true
					else
						# If the user is managing someone, we assume he is managed by the leave admin if not by someone else
						return true if self.is_managing?
						return false
					end
				end
			end

			# A user is managed by a leave admin only if
      # - He can create leave requests
      # - He is not a contractor
      # - He is not a leave admin for the project
      # - He manages people in the project, and does not appear only as a leave backup
      # - He is not managed by anybody in the project
			def is_managed_by_leave_admin?(project)
				return self.can_create_leave_requests && !self.is_rule_managed_in_project?(project) && self.leave_manages_project?(project, false) && !self.is_contractor && !self.is_leave_admin?(project) && !self.is_system_leave_admin?
			end


			def contractor_notifies_leave_admin?(project)
				return self.can_create_leave_requests && self.notify_rules_project(project).empty? && project.leave_management_rules_enabled?
			end

			# returns true if the user manages people on given project
			def leave_manages_project?(project, include_backups = true)
					return LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'is_managed_by', project, [], include_backups).any?
			end

			# Returns the list of project: managers for which the current user is a backup at a given date
			def leave_management_backup_project_list(date = Date.today)
				backup_rule_users = LeaveManagementRule.joins(:leave_exception_rules).where(action: LeaveManagementRule.actions["is_managed_by"], leave_exception_rules: {user_id: self.id, actor_concerned: LeaveExceptionRule.actors_concerned["backup_receiver"]}).flatten.map(&:to_users)

				users_on_leave = LeaveRequest.are_on_leave(backup_rule_users.map{|o| [o[:user_receivers].map(&:id)]}.flatten.uniq, date)

				rule_users_per_project= backup_rule_users.group_by{|r| r[:rule].project}

				managers = {}
				rule_users_per_project.each do |project, rules|
					managers[project] ||= []

					rules.each do |rule|
		        managers[project] << rule[:user_receivers] if rule[:user_receivers].map{|u| u.id.in?(users_on_leave)}.all?
      		end
				end
				return managers.delete_if {|k,v| v == []}
			end

			# Returns who the leave requests will be sent to, taking into account actual date
			def leave_notifications_for_management(date = Date.today)
				users_managing_self_projects = self.managed_users_with_backup_leave(date)
				
				users_to_notify = []
				#obj = {project: nil, users: []}
				#obj = {}
				# For each project where rules are defined for the user
				
				#notify_leave_admin = false

				users_managing_self_projects.each do |project, user_arrays|
					nesting = 0
					user_arrays.each do |users|
						size = users.size
						on_leave = users.select{|u| u[:is_on_leave] == true }.size
						users_to_notify << users.map{|u| u[:user] }
						if size != on_leave
							break
						else
							nesting += 1
						end
					end
					if nesting == user_arrays.size
						#notify_leave_admin = true
						users_to_notify << project.get_leave_administrators[:users]
					end
				end
				#if notify_leave_admin 
				#	users_to_notify << LeavesHolidaysLogic.plugin_admins_users
				#end

				# Should always send notification to users even if they are on leave. Additional users should be notified in such case.
				return users_to_notify.flatten.uniq
			end

			# Returns if user is a leave admin. 
			def is_leave_admin?(project = nil)
				return false if !self.active?
				if project != nil
					return self.in?(project.get_leave_administrators[:users])
				else
					return self.in?(LeavesHolidaysLogic.plugin_admins_users) || self.in?(LeaveAdministrator.all.includes(:user).map{|l| l.user})
				end
			end

			def is_system_leave_admin?
				return self.id.in?(LeavesHolidaysLogic.plugin_admins)
			end

			def is_project_leave_admin?(project)
				return false if project == nil
				return self.in?(project.get_leave_administrators[:users])
			end

			# returns project list where the user is actually a leave admin
			def leave_admin_projects
				projects = Project.system_leave_projects
				return LeavesHolidaysLogic.leave_administrators_for_projects(projects.to_a).select{|k,v| self.in?(v)}.keys
			end

			# Returns all leave projects regarding a user, where:
			# The user is a leave admin OR is a member OR is a leave backup AND
			# The plugin leave module is enabled AND Leave management rules are enabled.
			def leave_projects
				projects = Project.system_leave_projects
				project_ids_leave_admin = LeavesHolidaysLogic.leave_administrators_for_projects(projects.to_a).select{|k,v| self.in?(v)}.keys.map(&:id)
				project_ids_member = self.projects.system_leave_projects.pluck(:id)
				
				project_ids_leave_backup = LeaveExceptionRule.includes(:leave_management_rule).where(user: self, actor_concerned: LeaveExceptionRule.actors_concerned["backup_receiver"]).map{|e| e.leave_management_rule.project_id}

				return Project.where(id: project_ids_leave_admin | project_ids_member | project_ids_leave_backup)
			end

			# A user who is a project leave administrator can self approve his own requests only if he is not managed anywhere
			def can_self_approve_requests?
				# return false anyway if user is not a leave admin
				return false if !self.is_leave_admin?
				leave_admin_projects = LeaveAdministrator.where(user: self).pluck(:project_id)
				projects_managed = LeavesHolidaysManagements.management_rules_list(self, 'sender', 'is_managed_by').map(&:project_id)
				return true if (projects_managed - leave_admin_projects).empty?
				return false
			end

			# Returns the list of users who are managed by user at a given date.
			# options are to include users managed indirectly and as a backup.
			# Even if backup and indirect options are not selected, if the user effectively acts as a backup, or indirect users must be managed, those users will anyway be included in the list.
			def manage_users_summary(date = Date.today, options={})
				manage_full_list = self.manage_users_with_backup

				managers_list = manage_full_list[:directly].map{|h| h[:managers]} + manage_full_list[:directly].map{|h| h[:backups]} + manage_full_list[:indirectly].map{|h| h[:managers]} + manage_full_list[:indirectly].map{|h| h[:backups]}

				managers_list = managers_list.flatten.uniq - [self]
				managers_on_leave_ids = LeaveRequest.are_on_leave(managers_list.map(&:id), date)

				managed_directly = manage_full_list[:directly].select{|h| (self.in?(h[:managers]) || (options[:backup] && self.in?(h[:backups])) || (self.in?(h[:backups]) && (h[:managers].map(&:id) - managers_on_leave_ids).empty?))}.map{|h| h[:managed]}

				managed_indirectly = []

				managed_indirectly = manage_full_list[:indirectly].select{|h| options[:indirect] || ((h[:managers].map(&:id) + h[:backups].map(&:id)).flatten.uniq - managers_on_leave_ids).empty?  }.map{|h| h[:managed]}


				# project.users_managed_by_leave_admin
				managed_as_admin = []
				self.leave_admin_projects.each do |project|
					managed_as_admin << project.users_managed_by_leave_admin
					managed_as_admin << project.users.can_create_leave_request.not_contractor.to_a if options[:indirect]
				end

				list = (managed_directly + managed_indirectly + managed_as_admin).flatten.uniq
				list -= [self] unless self.can_self_approve_requests?
				list -= LeavesHolidaysLogic.plugin_admins_users unless self.is_system_leave_admin?
				return list
			end

			def managed_users_summary(date = Date.today, options={})
				managed_full_list = self.managed_users_with_backup

				managers_list = managed_full_list[:directly].map{|h| h[:managers]} + managed_full_list[:directly].map{|h| h[:backups]} + managed_full_list[:indirectly].map{|h| h[:managers]} + managed_full_list[:indirectly].map{|h| h[:backups]}

				managers_list = managers_list.flatten.uniq - [self]
				managers_on_leave_ids = LeaveRequest.are_on_leave(managers_list.map(&:id), date)

				managing_directly = managed_full_list[:directly].select{|h| (self.in?(h[:managers]) || (options[:backup] && self.in?(h[:backups])) || (self.in?(h[:backups]) && (h[:managers].map(&:id) - managers_on_leave_ids).empty?))}.map{|h| h[:managers]}

				managing_indirectly = []

				managing_indirectly = managed_full_list[:indirectly].select{|h| options[:indirect] || ((h[:managers].map(&:id) + h[:backups].map(&:id)).flatten.uniq - managers_on_leave_ids).empty?  }.map{|h| h[:managers]}


				managed_as_admin = []
				self.leave_admin_projects.each do |project|
					managed_as_admin << project.users_managed_by_leave_admin
					managed_as_admin << project.users.can_create_leave_request.not_contractor.to_a if options[:indirect]
				end

				list = (managing_directly + managing_indirectly + managed_as_admin).flatten.uniq
				list -= [self] unless self.can_self_approve_requests?
				list -= LeavesHolidaysLogic.plugin_admins_users unless self.is_system_leave_admin?
				return list
			end

			# returns a list of project / users where the current user is managed
			def managed_by_project_users
				managed_list = self.managed_rules
				project_ids = managed_list.flatten.map(&:project_id).uniq
				projects = Project.where(id: project_ids)
				out = {}
				projects.each do |project|
					list_for_project = managed_list.map{|rules| rules.select{|r| r.project_id == project.id }}.select{|rules| rules.any?}
					managed_list_users = list_for_project.map{|a| a.map(&:to_users)}
					out[project] = managed_list_users# if managed_list_users.flatten.any?
				end
				return out
			end

			# Leave Requests - Receiver Part

			def viewable_user_list
				return (self.manages_user_list + self.consulted_user_list + self.notified_user_list).flatten.uniq
			end

			# receiver manages senders
			def manages_user_list
				return [] unless self.can_manage_leave_requests
				return self.manage_users_summary(Date.today, {indirect: true, backup: true})
			end

			# receiver is consulted for approval from senders
			def consulted_user_list
				return [] unless self.can_be_consulted_leave_requests
				return self.consulted_rules.flatten.map(&:to_users).map{|t| t[:user_senders]}.flatten.uniq
			end

			# receiver is notified from senders approved leave requests
			def notified_user_list
				return [] unless self.can_be_notified_leave_requests
				return self.leave_projects.map{|p| p.users.can_create_leave_request}.flatten.uniq if LeavesHolidaysLogic.has_view_all_rights(self)
				return self.notified_rules.flatten.map(&:to_users).map{|t| t[:user_senders]}.flatten.uniq
			end

			# Leave Requests - Sender Part

			# sender is managed by receivers
			def managed_user_list

			end

			#sender consults for approval receivers
			def consults_user_list

			end

			#sender notifies for approved receivers
			def notifies_user_list

			end

			###

			def is_consulted_for_user?(user)
				return self.can_be_consulted_leave_requests && self.consulted_rules.flatten.map(&:to_users).select{|lmr| user.in?(lmr[:user_senders])}.any?
			end

			def is_notified_from_user?(user)
				return LeavesHolidaysLogic.has_view_all_rights(self) || self.can_be_notified_leave_requests && self.notified_rules.flatten.map(&:to_users).select{|lmr| user.in?(lmr[:user_senders])}.any?
			end

			def is_managing_user?(user)
				return self.can_manage_leave_requests && user.in?(self.manage_users_summary(Date.today, {indirect: true, backup: true}))
			end

			def project_consults_full_list
				consult_list = self.consult_rules
				project_ids = consult_list.map(&:project_id).uniq
				projects = Project.where(id: project_ids)

				out = {}
				projects.each do |project|
					list_for_project = consult_list.select{|r| r.project_id == project.id }
					consult_list_users = list_for_project.map(&:to_users)
					out[project] = consult_list_users.map{|r| r[:user_receivers]}.flatten.uniq
				end
				return out
			end

			# Returns the full list of users managing self for every project.
			def project_managed_by_full_list
				return {} if self.can_self_approve_requests?

				managed_list = self.managed_rules
				managing_rules = LeavesHolidaysManagements.management_rules_list(self, 'receiver', 'is_managed_by', [], [], false).to_a

				managed_project_ids = managed_list.flatten.map(&:project_id).uniq
				managed_projects = Project.where(id: managed_project_ids).to_a

				managing_project_ids = managing_rules.map(&:project_id).uniq
				managing_projects = Project.where(id: managing_project_ids).to_a

				not_managed_projects = managing_projects - managed_projects

				out = {}

				managed_projects.each do |project|
					list_for_project = managed_list.map{|rules| rules.select{|r| r.project_id == project.id }}.select{|rules| rules.any?}
					managed_list_users = list_for_project.map{|a| a.map(&:to_users)}

					out[project] = {}
					hsh = {}
					managed_list_users.each_with_index do |rules, nesting|
						level = nesting + 1
						hsh[level] = []
						rules.each do |rule|
							hsh[level] << {users: (rule[:user_receivers] - [self]), backups: (rule[:backup_list] - [self])}
						end
					end
					hsh[:leave_administrators] = [{users: (project.get_leave_administrators[:users] - [self]), backups: []}]
					out[project] = hsh
				end

				not_managed_projects.each do |project|
					out[project] = {}
					hsh = {}
					hsh[:leave_administrators] = [{users: (project.get_leave_administrators[:users] - [self]), backups: []}]
					out[project] = hsh
				end

				return out

			end

		end
	end
end

unless User.included_modules.include?(RedmineLeavesHolidays::Patches::UserPatch)
  User.send(:include, RedmineLeavesHolidays::Patches::UserPatch)
end