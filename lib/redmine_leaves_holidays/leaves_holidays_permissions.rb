module LeavesHolidaysPermissions

  def authenticate_leave_request(params={})
    case params[:action].to_sym
    when :index
      auth = @user.can_create_leave_requests
    when :new, :create
      auth = @user.can_create_leave_requests
    when :submit, :unsubmit, :edit, :update, :destroy
      auth = @user == @leave.user
    when :show
      @is_consulted = @user.is_consulted_for_user?(@leave.user)
      @is_notified = @user.is_notified_from_user?(@leave.user)
      @is_managing = @user.is_managing_user?(@leave.user)
      @has_view_all_rights = LeavesHolidaysLogic.has_view_all_rights(@user)
      auth = @user == @leave.user || (@leave.get_status != 'created' && (@has_view_all_rights || @is_consulted || @is_notified || @is_managing))
    end

    return auth
  end

  def authenticate_leave_votes(params={})
    auth = false
    case params[:action].to_sym
    when :new, :create
      auth = @user.is_consulted_for_user?(@leave.user)
    when :edit, :update
      auth = @user.is_consulted_for_user?(@leave.user) && @user == @vote.user
    when :index
      auth = @user.is_consulted_for_user?(@leave.user) || @user.is_managing_user?(@leave.user)
    end

    if auth && params[:action].to_sym != :index
      auth = @leave.request_status.in?(["submitted", "processing"])
    end

    return auth
  end

  def authenticate_leave_status(params={})
    auth = false
    case params[:action].to_sym
    when :new, :create, :show, :edit, :update
      auth = @user.is_managing_user?(@leave.user) && !@leave.request_status.in?(["created", "cancelled"])
    when :index
      auth = @user.can_manage_leave_requests || @user.can_be_consulted_leave_requests || @user.can_be_notified_leave_requests
    end

    return auth
  end

  def authenticate_leave_preferences(params={})
    auth = false

    case params[:action].to_sym
      when :index, :new, :create, :edit, :bulk_edit, :bulk_update, :update, :destroy, :notification, :manage_pending_days, :clear_filters
        auth = @user.allowed_to?(:manage_user_leave_preferences, nil, :global => true)
      when :show
        auth = @user == @user_pref || @user.allowed_to?(:manage_user_leave_preferences, nil, :global => true)
    end

    return auth
  end

end