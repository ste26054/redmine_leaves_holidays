module LeavesHolidaysManagements

 def self.actor_types
  return ['Role', 'User']
 end

 def self.default_actor_type
  return self.actor_types[0]
 end
end