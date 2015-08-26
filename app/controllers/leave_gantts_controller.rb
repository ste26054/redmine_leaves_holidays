class LeaveGanttsController < ApplicationController
  unloadable

  helper :leave_requests
  include LeaveRequestsHelper
  
  before_action :set_user

  def show

  end

  private

  def set_user
    @user ||= User.current
  end

end