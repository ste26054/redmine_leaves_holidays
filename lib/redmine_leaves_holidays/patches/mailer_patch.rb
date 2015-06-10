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

        cc = []
        subject = "[Leave Request - #{leave.issue.subject} \##{leave.id}] Consulted by #{@user.name}"

        # mail :to => [User.find(87), User.find(91)], :cc => cc, :subject => subject
        mail :to => recipients, :cc => cc, :subject => subject
      end

        

    end
  end	
end