module LeaveManagementRulesHelper
  include LeavesHolidaysManagements
  
  def actor_type_options_for_select(selected)
    options = LeavesHolidaysManagements.actor_types
    options_for_select(options, selected)
  end

  # Given an actor, "sender" or "receiver", remove selected from available options for opposite actor.
  def actor_collection_for_select_options(project, actor)
    return [] unless actor.in?(['sender', 'receiver'])
    actor_opposite = actor == 'sender' ? 'receiver' : 'sender'

    receiver_type = @receiver_type || LeavesHolidaysManagements.default_actor_type
    sender_type = @sender_type || LeavesHolidaysManagements.default_actor_type

    actor_type = actor == 'sender' ? sender_type : receiver_type

    list = project.send(actor_type.underscore + "_list")

    list_opposite_ids = actor_opposite == 'sender' ? @sender_list_id : @receiver_list_id

    if sender_type == receiver_type && list_opposite_ids
      list_opposite = list_opposite_ids.map{|e| e.to_i}
      list.delete_if {|l| l.id.in?(list_opposite)}
    end
    return list.map{|l| [l.name, l.id]}
  end

  def action_sender_options_for_select(selected)
    options = LeaveManagementRule.actions.to_a.map{|a| [a[0].humanize, a[1]]}.reverse
    options_for_select(options, selected)
  end
end