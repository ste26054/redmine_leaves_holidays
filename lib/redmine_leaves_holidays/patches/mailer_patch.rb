module RedmineLeavesHolidays
  module Patches

    module MailerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
      end 
    end

    module InstanceMethods

    	def leave_request_message(recipients, leave)
        redmine_headers 'LeaveRequest-Id' => leave.id,
                    'LeaveRequest-Author' => leave.user.login

         message_id leave
         references leave
    		@leave = leave
    		cc = []
    		subject = "Leave Request Creation \##{leave.id}"

    		
        
        	mail :to => recipients, :cc => cc, :subject => subject
    	end


        

    end
  end	
end