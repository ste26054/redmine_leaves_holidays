module RedmineLeavesHolidays
  module Patches

    module MailerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
      end 
    end

    module InstanceMethods

    	def leave_request_add(recipients, leave, arg)
        redmine_headers 'LeaveRequest-Id' => leave.id,
                    'LeaveRequest-Author' => leave.user.login

         message_id leave
         references leave
    		@leave = leave
        @user = arg[:user]
        @recp = recipients.collect { |r| r.login }
        
    		cc = []
        
    		subject = l(:mailer_leave_add_subject, :subject => leave.issue.subject, :id => leave.id, :user => @user.name)

       	mail :to => recipients, :cc => cc, :subject => subject
    	end

      def leave_request_update(recipients, leave, arg)
        redmine_headers 'LeaveRequest-Id' => leave.id,
                    'LeaveRequest-Author' => leave.user.login

         message_id leave
         references leave
        @leave = leave
        @user = arg[:user]
        @action = arg[:action]
        @recp = recipients.collect { |r| r.login }
        cc = []

        subject = l(:mailer_leave_update_subject, :subject => leave.issue.subject, :id => leave.id, :action => @action.capitalize, :user => @user.name)

        mail :to => recipients, :cc => cc, :subject => subject
      end


      def leave_vote_mail(recipients, leave, arg)
        redmine_headers 'LeaveRequest-Id' => leave.id,
                    'LeaveRequest-Author' => leave.user.login

         message_id leave
         references leave
        @leave = leave
        @user = arg[:user]
        @vote = arg[:vote]
        @recp = recipients.collect { |r| r.login }

        cc = []
        subject = l(:mailer_leave_consulted_subject, :subject => leave.issue.subject, :id => leave.id, :user => @user.name)

        mail :to => recipients, :cc => cc, :subject => subject
      end

      def leave_general_notification(recipients, user, additional_text="")
        redmine_headers 'Request-Author' => user.login

         message_id user
         references user
        @user_init = user
        @recp = recipients.collect { |r| r.login }
        @text = additional_text
        cc = []

        subject = l(:mailer_leave_general_notif, :user => @user_init.name)

        mail :to => recipients, :cc => cc, :subject => subject
      end

      def leave_training_feedback(leave)
        redmine_headers 'LeaveRequest-Id' => leave.id,
                    'LeaveRequest-Author' => leave.user.login

         message_id leave
         references leave
        @leave = leave
        @training_url = RedmineLeavesHolidays::Setting.defaults_settings(:training_form_url)
        cc = []
        subject = l(:mailer_training_feedback_subject, :subject => leave.issue.subject, :id => leave.id)

        mail :to => [leave.user], :cc => cc, :subject => subject
      end

    end
  end	
end

unless ApplicationController.included_modules.include?(RedmineLeavesHolidays::Patches::MailerPatch)
    Mailer.send(:include,RedmineLeavesHolidays::Patches::MailerPatch)
end