module LeaveManagementRulesHelper
  include LeavesHolidaysManagements
  
  def actor_type_options_for_select(selected)
    options = LeavesHolidaysManagements.actor_types
    options_for_select(options, selected)
  end

  # Given an actor, "sender" or "receiver", remove selected from available options for opposite actor.
  def actor_collection_for_select_options(project, actor)
    # Return empty list if actor is not a sender nor a receiver
    return [] unless actor.in?(['sender', 'receiver'])
    # Gets the opposite actor of the actor given sender -> receiver, etc.
    actor_opposite = actor == 'sender' ? 'receiver' : 'sender'

    # Gets the type of the sender/receiver, User or Role
    receiver_type = @receiver_type# || LeavesHolidaysManagements.default_actor_type
    sender_type = @sender_type#|| LeavesHolidaysManagements.default_actor_type

    # If actor is the sender, get sender type. otherwise, get receiver type
    actor_type = actor == 'sender' ? sender_type : receiver_type
    actor_opposite_type = actor_opposite == 'sender' ? sender_type : receiver_type
    # Get a list of roles or users with regards to the actor type provided
    list = project.send(actor_type.underscore + "_list")

    # Get the list of ids already selected previously for the other actor
    list_opposite_ids = actor_opposite == 'sender' ? @sender_list_id : @receiver_list_id
    
    # if the list is not empty
    if list_opposite_ids
      list_opposite = list_opposite_ids.map{|e| e.to_i}
      if actor_type == actor_opposite_type
        list.delete_if {|l| l.id.in?(list_opposite)}
        return list.map{|l| [l.name, l.id]}
      else
        if actor_opposite_type == 'Role' && actor_type == 'User'
          actor_opposite_roles_selected = Role.where(id: list_opposite).to_a
          actor_opposite_associated_user_ids = project.users_for_roles(actor_opposite_roles_selected).map(&:id)
          list.delete_if {|l| l.id.in?(actor_opposite_associated_user_ids)}
          return list.map{|l| [l.name, l.id]}
        end
      end
    end

    return list.map{|l| [l.name, l.id]}.sort_by{|t| t[0]}
  end

  def sender_exception_collection_for_select_options(project)
    return [] if @sender_type != "Role" || !@sender_list_id || @sender_list_id.empty?
    sender_roles_selected = Role.where(id: @sender_list_id.map{|e| e.to_i}).to_a
    users_associated_with_roles_selected = project.users_for_roles(sender_roles_selected)
    #return [] if users_associated_with_roles_selected.count == 1
    return users_associated_with_roles_selected.sort_by(&:name).map{|l| [l.name, l.id]}
  end

  def receiver_exception_collection_for_select_options(project)
    return [] if @receiver_type != "Role" || !@receiver_list_id || @receiver_list_id.empty?
    receiver_roles_selected = Role.where(id: @receiver_list_id.map{|e| e.to_i}).to_a
    users_associated_with_roles_selected = project.users_for_roles(receiver_roles_selected)
    #return [] if users_associated_with_roles_selected.count == 1
    return users_associated_with_roles_selected.sort_by(&:name).map{|l| [l.name, l.id]}
  end

  def backup_receiver_collection_for_select_options#(project)
    return [] if @action.to_i != LeaveManagementRule.actions['is_managed_by']
    #receiver_roles_selected = Role.where(id: @receiver_list_id.map{|e| e.to_i}).to_a
    #users_associated_with_roles_selected = project.users_for_roles(receiver_roles_selected)
    #return [] if users_associated_with_roles_selected.count == 1
    return User.all.active.sort_by(&:name).map{|l| [l.name, l.id]}
  end

  def action_sender_options_for_select(selected)
    options = LeaveManagementRule.actions.to_a.map{|a| [a[0].humanize, a[1]]}.reverse
    options_for_select(options, selected)
  end

  def user_options_for_select(selected)
    options = User.all.active.sort_by(&:name).map{|l| [l.name, l.id]}
    return options_for_select(options, selected)
  end

end
