module RedmineLeavesHolidays
  module Patches
    module MailerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
      end 
    end

    module InstanceMethods

    	def leave_request_message(recipients)
    		
    		cc = []
    		subject = "TEST LEAVE EMAIL"

    		@url = edit_user_leave_preferences_path(User.current)
        
        	mail :to => recipients, :cc => cc, :subject => subject
    	end

    end
  end	
end