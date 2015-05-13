class LeavePreferencesController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  before_action :set_user
  before_action :set_leave_preference
  before_action :set_holidays, only: [:new, :create, :edit, :update]
  before_action :check_rights, only: [:create, :update, :destroy]


  def new
  	if @preference != nil
      # redirect_to leave_request_leave_status_path
      redirect_to edit_user_leave_preferences_path
    else
  		@preference = LeavePreference.new
  		@preference.weekly_working_hours = RedmineLeavesHolidays::Setting.defaults_settings(:default_working_hours_week)
  		@preference.annual_leave_days_max = RedmineLeavesHolidays::Setting.defaults_settings(:default_days_leaves_year)
  		@preference.region = RedmineLeavesHolidays::Setting.defaults_settings(:region)
  		@preference.contract_start_date = RedmineLeavesHolidays::Setting.defaults_settings(:default_contract_start_date)
		@preference.extra_leave_days = 0.0
  	end
  end

  def create
  	@preference = LeavePreference.new(leave_preference_params) if @preference == nil
	  	if @preference.save
	      flash[:notice] = "Preferences were sucessfully saved for user #{@user.name}"
	  		redirect_to edit_user_path(@user)
	  	else
	  		flash[:error] = "Invalid preferences"
	  		redirect_to new_user_leave_preferences_path
	  	end
  end

  def edit

  end

  def update
  	if @preference.update(leave_preference_params)
  	   flash[:notice] = "Preferences were sucessfully saved for user #{@user.name}"
       redirect_to edit_user_path(@user)
    else
    	flash[:error] = "Invalid preferences"
       redirect_to edit_user_leave_preferences_path
    end
  end

  def destroy
	@preference.destroy
	redirect_to edit_user_path(@user)
  end


private

  def leave_preference_params
  	params.require(:leave_preference).permit(:user_id, :weekly_working_hours, :annual_leave_days_max, :region, :contract_start_date, :extra_leave_days)
  end

  def set_user
      @user = User.current
  end

  def set_holidays
	@regions = LeavesHolidaysLogic.get_region_list
  end

  def set_leave_preference
  	@exists = false
    @preference = LeavePreference.where(user_id: @user.id).first if @preference == nil
    @exists = true if @preference != nil
  end

  def check_rights
  	unless @user.allowed_to?(:manage_user_leaves_preferences, nil, :global => true)
		flash[:error] = "You do not have sufficient rights to change these settings"
	  	redirect_to new_user_leave_preferences_path
	  	return
	end
  end

end