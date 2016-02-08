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

        @deadline = @leave.deadline
        if (@deadline < Date.today)
          @deadline = nil
        end

    		cc = []
    		subject = "[Leave Request - #{leave.issue.subject} \##{leave.id}] Submitted by #{@user.name}"

        # mail :to => [User.find(87), User.find(91)], :cc => cc, :subject => subject
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
        subject = "[Leave Request - #{leave.issue.subject} \##{leave.id}] #{@action.capitalize} by #{@user.name}"

        # mail :to => [User.find(87), User.find(91)], :cc => cc, :subject => subject
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
        subject = "[Leave Request - #{leave.issue.subject} \##{leave.id}] Consulted by #{@user.name}"

        # mail :to => [User.find(87), User.find(91)], :cc => cc, :subject => subject
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
        subject = "[Leave Request - General Notification] Initiated by #{@user_init.name}"

        mail :to => recipients, :cc => cc, :subject => subject
      end

    end
  end	
end

unless ApplicationController.included_modules.include?(RedmineLeavesHolidays::Patches::MailerPatch)
    Mailer.send(:include,RedmineLeavesHolidays::Patches::MailerPatch)
end