module LeaveManagementRulesHelper
  include LeavesHolidaysManagements
  
  def actor_type_options_for_select(selected)
    options = LeavesHolidaysManagements.actor_types
    options_for_select(options, selected)
  end

  def sender_collection_for_select_options(project)
    sender_type = @sender_type || LeavesHolidaysManagements.default_actor_type
    list = project.send(sender_type.underscore + "_list")
    return list.map{|l| [l.name, l.id]}
  end

  def receiver_collection_for_select_options(project)
    receiver_type = @receiver_type || LeavesHolidaysManagements.default_actor_type
    list = project.send(receiver_type.underscore + "_list")
    return list.map{|l| [l.name, l.id]}
  end

  def action_sender_options_for_select(selected)
    options = LeaveManagementRule.actions.to_a.map{|a| [a[0].humanize, a[1]]}
    options_for_select(options, selected)
  end
end