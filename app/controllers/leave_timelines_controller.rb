class LeaveTimelinesController < ApplicationController
  unloadable

  helper :leave_requests
  include LeaveRequestsHelper
  
  before_action :set_user

  def show

    @timeline = RedmineLeavesHolidays::Helpers::Timeline.new(params)
    @timeline.leave_list = LeaveRequest.all.overlaps(@timeline.date_from, @timeline.date_to).not_rejected

    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
    end
  end

  private

  def set_user
    @user ||= User.current
  end

end