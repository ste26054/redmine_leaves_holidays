class LeaveRule < ActiveRecord::Base
  unloadable

  belongs_to :issue
  validates :issue, presence: true

  # validates :is_deduced_from_entitlement, :inclusion => {:in => [true, false]}

  # enum availability: {non_contractors: 0, contractors: 1, everyone: 2}
  # validates :availability, presence: true, inclusion: { in: LeaveRule.availabilities.keys }

  # enum approval: {leave_management_rules: 0, self_approved: 1, designed_people: 2}
  # validates :approval, presence: true, inclusion: { in: LeaveRule.approvals.keys }
  
  # validates :limit_count, presence: true, numericality: true, inclusion: {in: 0..365}

  # enum limit_unit: {working_days: 0, working_weeks: 1, calendar_days: 3, calendar_weeks: 4}
  # validates :limit_unit, presence: true, inclusion: { in: LeaveRule.limit_units.keys }

  # enum limit_reference: {leave_period: 0, calendar_year: 1}
  # validates :limit_reference, presence: true, inclusion: { in: LeaveRule.limit_references.keys }

  # validates_length_of :limit_exceeded_message, :maximum => 255
  


  has_and_belongs_to_many :custom_fields, :class_name => 'LeaveRequestCustomField', :join_table => "#{table_name_prefix}custom_fields_leave_rules#{table_name_suffix}", :association_foreign_key => 'custom_field_id'


  attr_accessible :custom_field_ids, :issue_id

  def leave_requests
    issue_id = self.issue_id
    LeaveRequest.where(issue_id: issue_id)
  end
end