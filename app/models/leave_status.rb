class LeaveStatus < ActiveRecord::Base
  unloadable
  
  belongs_to :user
  belongs_to :leave_request

  before_destroy :set_submitted
  before_validation :set_user


  enum acceptance_status: { rejected: 0, accepted: 1 }

  validates :user_id, presence: true
  validates :leave_request_id, presence: true
  validates :acceptance_status, presence: true

  attr_accessor :timestamp
  attr_accessible :acceptance_status, :leave_request_id, :comments, :timestamp

  scope :rejected, -> { where(acceptance_status: "0") }
  scope :accepted, -> { where(acceptance_status: "1") }
  scope :processed_by_user, ->(uid) { where('user_id = ?', uid) }
  scope :for_request, ->(rid) { where('leave_request_id = ?', rid) }


  private


  def set_user
    self.user_id = User.current.id
  end

  def set_submitted
    if LeaveRequest.where(:id => self.leave_request_id).any?
      req = LeaveRequest.find(self.leave_request_id)
      req.update_attribute(:request_status, "submitted")
    end
  end



end
