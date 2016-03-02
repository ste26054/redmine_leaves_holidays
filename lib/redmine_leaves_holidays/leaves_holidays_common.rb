module LeaveHolidaysCommon
  def set_user
    @user = User.current
  end
end