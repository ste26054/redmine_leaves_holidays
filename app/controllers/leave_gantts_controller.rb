class LeaveGanttsController < ApplicationController
  unloadable

  helper :leave_requests
  include LeaveRequestsHelper
  
  before_action :set_user

  def show
    @lenght = params[:lenght] || 1
    @month = params[:from_month] || Date.current.month
    @year = params[:from_year] || Date.current.year

    from = Date.new(@year.to_i,@month.to_i,1)
    to = from + @lenght.to_i.months
    @leave_list = LeaveRequest.all.overlaps(from, to).not_rejected
    @data = @leave_list.to_datatable.to_json
  end

  private

  def set_user
    @user ||= User.current
  end

end