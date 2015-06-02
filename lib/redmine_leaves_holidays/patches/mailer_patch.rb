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
        @arg = arg
    		cc = []
    		subject = "Leave Request \##{leave.id} Submission"

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
        subject = "Leave Request \##{leave.id} Update"

        mail :to => recipients, :cc => cc, :subject => subject
      end


        

    end
  end	
end