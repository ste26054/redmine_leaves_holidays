class LeavePreferencesController < ApplicationController
  unloadable
  include LeavesHolidaysLogic
  
  before_action :set_user
  before_action :set_leave_preference
  before_filter :authenticate, except: [:show]
  before_action :set_holidays, only: [:new, :create, :edit, :update]

  def new
  	if @exists
      redirect_to edit_user_leave_preferences_path
    else
  		@preference = LeavesHolidaysLogic.retrieve_leave_preferences(@user)
  	end
  end

  def create
  	@preference = LeavePreference.new(leave_preference_params) unless @exists
    @preference.user_id = @user_pref.id
  	if @preference.save
      flash[:notice] = "Preferences were sucessfully saved for user #{@user_pref.name}"
  		redirect_to edit_user_leave_preferences_path
  	else
  		flash[:error] = "Invalid preferences"
  		redirect_to new_user_leave_preferences_path
  	end
  end

  def show
    render_403 unless LeavesHolidaysLogic.has_right(@user, @user_pref, @preference, :show)
  end

  def edit
  end

  def update
    @preference.user_id = @user_pref.id
  	if @preference.update(leave_preference_params)
  	   flash[:notice] = "Preferences were sucessfully updated for user #{@user_pref.name}"
    else
    	flash[:error] = "Invalid preferences"
    end
    redirect_to edit_user_leave_preferences_path
  end

  def destroy
  	@preference.destroy
  	redirect_to edit_user_leave_preferences_path
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
      @preference = LeavesHolidaysLogic.retrieve_leave_preferences(@user)
    end
  end

  def authenticate
    unless LeavesHolidaysLogic.has_right(@user, @user_pref, @preference, params[:action].to_sym)
      redirect_to user_leave_preferences_path
      return
    end
  end
end