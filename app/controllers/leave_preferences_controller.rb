class LeavePreferencesController < ApplicationController
  unloadable
  include LeavesHolidaysLogic

  helper :leave_requests
  include LeaveRequestsHelper
  
  before_action :set_user
  before_action :set_user_preferences, except: [:index, :bulk_edit, :bulk_update, :clear_filters]
  before_action :authenticate, except: [:show, :notification]
  before_action :set_holidays, only: [:new, :create, :edit, :bulk_edit, :update, :bulk_update]

  def clear_filters
      remove_filters
      redirect_to leave_preferences_path
  end

  def index
    if params[:commit] && params[:commit] == "apply"
      remove_filters
    end

    @projects_initial = Project.all.active    
    if params[:projects].present?
      @projects_selected = @projects_initial.where(id: params[:projects])
      @user.pref[:leave_preference_filters_projects] = params[:projects]
      @user.preference.save
    else
      @projects_selected = @projects_initial.where(id: @user.pref[:leave_preference_filters_projects]) if @user.pref[:leave_preference_filters_projects].present?
    end

    projects = @projects_initial
    projects = @projects_selected if @projects_selected


    @roles_initial = Role.all.givable
    if params[:roles].present?
      @roles_selected = params[:roles]
      @user.pref[:leave_preference_filters_roles] = params[:roles]
      @user.preference.save
    else
      @roles_selected = @user.pref[:leave_preference_filters_roles] if @user.pref[:leave_preference_filters_roles].present?
    end

    roles = @roles_initial
    roles = Role.where(id: @roles_selected) if @roles_selected
    

    @users_initial = LeavesHolidaysLogic.users_for_projects(@projects_initial)

    @regions_initial = @users_initial.joins(:leave_preference).group("leave_preferences.region").count.to_hash.keys + [RedmineLeavesHolidays::Setting.defaults_settings(:region)]
    @regions_initial = @regions_initial.uniq
    
    if params[:region].present?
      @regions_selected = params[:region]
      @user.pref[:leave_preference_filters_regions] = params[:region]
      @user.preference.save
    else
      @regions_selected = @user.pref[:leave_preference_filters_regions] if @user.pref[:leave_preference_filters_regions].present?
    end


    @users_selected = @users_initial
    @users_selected = @users_initial.like(params[:name]) if params[:name].present?
    @users_selected = @users_selected.with_leave_region(@regions_selected) if @regions_selected
    @users_selected = LeavesHolidaysLogic.users_with_roles_for_projects(roles, projects) & @users_selected
  end

  def new
  	if @exists
      redirect_to edit_user_leave_preference_path
  	end
  end

  def create
  	@preference = LeavePreference.new(leave_preference_params) unless @exists
    @preference.user_id = @user_pref.id
  	if @preference.save
      event = LeaveEvent.new(user_id: @user_pref.id, event_type: "user_pref_manual_create", comments: "changed_by: #{User.current.login}")
      event.event_data = @preference.attributes
      event.save
      flash[:notice] = "Preferences were sucessfully saved for user #{@user_pref.name}"
  		redirect_to edit_user_leave_preference_path
  	else
  		flash[:error] = "Invalid preferences"
  		render :new
  	end
  end

  def show
    render_403 unless LeavesHolidaysLogic.has_right(@user, @user_pref, @preference, :show)
  end

  def edit
  end

  def bulk_edit
    if params.has_key?(:user_ids)
      if params[:user_ids].count == 1
        redirect_to new_user_leave_preference_path(User.find(params[:user_ids])) and return
      else
        users = User.find(params[:user_ids])
        @users_preferences = users.map{|u| u.leave_preferences}
      end
    else
      flash[:warning] = "Please select at least one item from the list"
      redirect_to leave_preferences_path
    end
  end

  def bulk_update
    users_preferences = User.find(params[:user_ids]).map{|u| u.leave_preferences}
    users_preferences.each do |user_pref|
      success = user_pref.update_attributes(params[:preferences].reject { |k,v| v.blank? })
      if !success 
        flash[:error] = "Invalid preferences"
        redirect_to :controller => 'leave_preferences', :action => 'bulk_edit', :user_ids => params[:user_ids] and return
      else
        event = LeaveEvent.new(user_id: user_pref.user_id, event_type: "user_pref_manual_update", comments: "changed_by: #{User.current.login}")
        event.event_data = user_pref.attributes
        event.save
      end
    end
    flash[:notice] = "Preferences were sucessfully updated"
    redirect_to leave_preferences_path
  end

  def update
    @preference.user_id = @user_pref.id
  	success = @preference.update(leave_preference_params)
      
    respond_to do |format|
      format.html { 
        if !success 
          flash[:error] = "Invalid preferences"
          render :edit
        else
          event = LeaveEvent.new(user_id: @user_pref.id, event_type: "user_pref_manual_update", comments: "changed_by: #{User.current.login}")
          event.event_data = @preference.attributes
          event.save
          flash[:notice] = "Preferences were sucessfully updated for user #{@user_pref.name}"
          redirect_to edit_user_leave_preference_path
        end
      }
      format.js
    end
  end

  def destroy
    event = LeaveEvent.new(user_id: @user_pref.id, event_type: "user_pref_deleted", comments: "changed_by: #{User.current.login}")
    event.event_data = @preference.attributes
    event.save
  	@preference.destroy
  	redirect_to edit_user_leave_preference_path
  end

  def notification
    @vote_list = LeavesHolidaysLogic.users_allowed_common_project(@user_pref, 2)
    @manage_list = LeavesHolidaysLogic.users_allowed_common_project(@user_pref, 3)
    # @manage_list = LeaveManagementRule.management_rules_list_recursive(@user_pref, 'sender', 'is_managed_by')
  end

  def manage_pending_days
    if params[:accept] && params[:accept].in?(["false", "true"])
      if params[:accept] == "true"
        @preference.extra_leave_days += @preference.pending_day_count
      end
      @preference.pending_day_count = 0.0
      @preference.save
      event = LeaveEvent.new(user_id: @user_pref.id, event_type: "user_pref_manual_update", comments: "changed_by: #{User.current.login}")
      event.event_data = @preference.attributes
      event.save
    end
    redirect_to edit_user_leave_preference_path
  end

private

  def leave_preference_params
  	params.require(:leave_preference).permit(:user_id, :weekly_working_hours, :annual_leave_days_max, :region, :contract_start_date, :contract_end_date, :extra_leave_days, :is_contractor, :annual_max_comments, :leave_renewal_date, :overall_percent_alloc, :can_create_leave_requests)
  end

  def set_user
      @user = User.current
  end

  def set_user_preferences
      @user_pref = User.find(params[:user_id])
      @preference = @user_pref.leave_preferences
      @exists = (@preference.id != nil)
  end

  def set_holidays
	  @regions = LeavesHolidaysLogic.get_region_list
  end

  def remove_filters
    @user.pref[:leave_preference_filters_projects] = nil
    @user.pref[:leave_preference_filters_roles] = nil
    @user.pref[:leave_preference_filters_regions] = nil
    @user.pref[:leave_preference_filters_users] = nil
    @user.preference.save
  end

  def authenticate
    # unless action_name.in?(["index", "bulk_edit", "bulk_update", "clear_filters"])
    #   unless LeavesHolidaysLogic.has_right(@user, @user_pref, @preference, params[:action].to_sym)
    #     redirect_to user_leave_preference_path
    #     return
    #   end
    # else
      render_403 unless LeavesHolidaysLogic.has_manage_user_leave_preferences(@user)
    #end
  end
end