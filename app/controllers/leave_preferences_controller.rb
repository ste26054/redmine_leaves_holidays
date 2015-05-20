class LeavePreferencesController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  before_action :set_user
  before_action :set_leave_preference
  before_action :set_holidays, only: [:new, :create, :edit, :update]
  before_action :check_rights, only: [:new, :create, :edit, :update, :destroy]


  def new
  	if @exists
      redirect_to edit_user_leave_preferences_path
    else
  		retrieve_leave_preferences
  	end
  end

  def create
  	@preference = LeavePreference.new(leave_preference_params) unless @exists
    @preference.user_id = @user_pref.id
  	if @preference.save
      flash[:notice] = "Preferences were sucessfully saved for user #{@user_pref.name}"
  		redirect_to edit_user_path(@user_pref)
  	else
  		flash[:error] = "Invalid preferences"
  		redirect_to new_user_leave_preferences_path
  	end
  end

  def show
  end

  def edit
  end

  def update
    @preference.user_id = @user_pref.id
  	if @preference.update(leave_preference_params)
  	   flash[:notice] = "Preferences were sucessfully updated for user #{@user_pref.name}"
       redirect_to edit_user_path(@user_pref)
    else
    	flash[:error] = "Invalid preferences"
       redirect_to edit_user_leave_preferences_path
    end
  end

  def destroy
  	@preference.destroy
  	redirect_to edit_user_path(@user_pref)
  end


private

  def leave_preference_params
  	params.require(:leave_preference).permit(:user_id, :weekly_working_hours, :annual_leave_days_max, :region, :contract_start_date, :extra_leave_days, :is_contractor, :annual_max_comments)
  end

  def set_user
      @user = User.current
      @user_pref = User.find(params[:user_id])
  end

  def set_holidays
	@regions = LeavesHolidaysLogic.get_region_list
  end

  def set_leave_preference
    @preference = nil
    @preference = LeavePreference.where(user_id: @user_pref.id).first
    @exists = (@preference != nil)
    if @preference == nil
      retrieve_leave_preferences
    end
  end

  def check_rights
  	unless @user.allowed_to?(:manage_user_leaves_preferences, nil, :global => true)
		# flash[:error] = "You do not have sufficient rights to change these settings"
	 #  	redirect_to new_user_leave_preferences_path
	 #  	return
      redirect_to user_leave_preferences_path
      return
	  end
  end

  def retrieve_leave_preferences
      @preference = LeavePreference.new
      @preference.weekly_working_hours = RedmineLeavesHolidays::Setting.defaults_settings(:weekly_working_hours)
      @preference.annual_leave_days_max = RedmineLeavesHolidays::Setting.defaults_settings(:annual_leave_days_max)
      @preference.region = RedmineLeavesHolidays::Setting.defaults_settings(:region)
      @preference.contract_start_date = RedmineLeavesHolidays::Setting.defaults_settings(:contract_start_date)
      @preference.extra_leave_days = 0.0
      @preference.is_contractor = RedmineLeavesHolidays::Setting.defaults_settings(:is_contractor)
      @preference.user_id = @user_pref.id
  end

end