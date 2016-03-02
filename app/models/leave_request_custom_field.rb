class LeaveRequestCustomField < CustomField

  has_and_belongs_to_many :leave_rules, :join_table => "#{table_name_prefix}custom_fields_leave_rules#{table_name_suffix}", :foreign_key => "custom_field_id"
  has_many :leave_requests, :through => :leave_requests_custom_values

  def type_name
    :leave_short
  end
end