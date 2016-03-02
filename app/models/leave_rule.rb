class LeaveRule < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes
  belongs_to :issue

  validates :issue, presence: true

  

end