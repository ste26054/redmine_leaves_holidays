class LeaveManagementRule < ActiveRecord::Base
  unloadable

  belongs_to :sender, polymorphic: true # Sender can be a Role or a User
  belongs_to :receiver , polymorphic: true # receiver can be a Role or a User

  has_many :leave_exception_rules, dependent: :destroy

  # Sender [notifies, is consulted by, is managed by] Receiver
  enum action: { notifies_approved: 0, is_consulted_by: 1, is_managed_by: 2 } #Action to make
  belongs_to :project

  validates :action, presence: true, inclusion: { in: LeaveManagementRule.actions.keys }
  validates :sender, presence: true
  validates :receiver, presence: true
  validates :project, presence: true
  validates :action, presence: true

  validate :validate_sender_not_receiver
  validate :validate_rule_uniq
  validate :validate_no_cyclic_rule

  before_save :check_principal

  scope :sender_role, lambda { where(sender_type: "Role") }
  scope :receiver_role, lambda { where(receiver_type: "Role") }
  scope :sender_user, lambda { where(sender_type: "Principal") }
  scope :receiver_user, lambda { where(receiver_type: "Principal") }


  def check_principal
    if self.sender_type == "Principal"
      self.sender_type = "User"
    end
    if self.receiver_type == "Principal"
      self.receiver_type = "User"
    end
  end

  def self.projects
    Project.where(id: LeaveManagementRule.select('distinct project_id').map(&:project_id)).active
  end

  def sender_list
    actor_list('sender')
  end

  def receiver_list
    actor_list('receiver')
  end

  def sender_type_form
    return sender_type if sender_type == "Role"
    return "User"
  end

  def receiver_type_form
    return receiver_type if receiver_type == "Role"
    return "User"
  end


  private

  def validate_sender_not_receiver
    if sender && receiver && sender == receiver
      errors.add(:sender, "cannot be the same as the receiver")
    end
  end

  def validate_rule_uniq
    rule_idtq =  LeaveManagementRule.where(sender: self.sender, receiver: self.receiver, project: self.project, action: LeaveManagementRule.actions[self.action])
    if self.id
      rule_idtq = rule_idtq.not(id: self.id)
    end
    errors.add(:base, "cannot add duplicate rules") if rule_idtq.count > 0
  end

  def validate_no_cyclic_rule
    cyclic_rule = LeaveManagementRule.where(sender: self.receiver, receiver: self.sender, project: self.project, action: LeaveManagementRule.actions[self.action])
    unless cyclic_rule.empty? 
      errors.add(:base, "cannot add cyclic rules within project")
    end
  end


  def actor_list(actor)
    return [] unless actor.in?(['sender', 'receiver'])
    if self.send(actor).class == Role
      user_list = self.project.users_for_roles(self.send(actor))
      return user_list if self.leave_exception_rules.empty?
      return user_list - self.leave_exception_rules.includes(:user).where(actor_concerned: LeaveExceptionRule.actors_concerned[actor]).map(&:user)
    else
      return [self.send(actor)]
    end
  end

end