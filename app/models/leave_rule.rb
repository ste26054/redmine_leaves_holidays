class LeaveRule < ActiveRecord::Base
  unloadable

  belongs_to :issue
  validates :issue, presence: true

  has_and_belongs_to_many :custom_fields, :class_name => 'LeaveRequestCustomField', :join_table => "#{table_name_prefix}custom_fields_leave_rules#{table_name_suffix}", :association_foreign_key => 'custom_field_id'


  attr_accessible :custom_field_ids, :issue_id

  def leave_requests
    issue_id = self.issue_id
    LeaveRequest.where(issue_id: issue_id)
  end
end