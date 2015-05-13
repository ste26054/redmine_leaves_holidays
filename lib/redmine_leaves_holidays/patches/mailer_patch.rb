module RedmineLeavesHolidays
  module Patches
    module MailerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
      end 
    end

    module InstanceMethods


    end
  end	
end