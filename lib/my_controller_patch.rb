require 'leaves_holidays'

#class LeavesHolidaysController < ApplicationController

module LeavesHolidaysPlugin
	module MyControllerPatch
		def self.included(base)
			base.class_eval do			
				# helper :attachments
				# include AttachmentsHelper
					# acts_as_attachable
			end
		end

		include LeavesHolidays

	end





end