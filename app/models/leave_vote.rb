class LeaveVote < ActiveRecord::Base
	unloadable

	belongs_to :leave_request
	belongs_to :user

	before_validation :set_user

	enum vote: { no: 0, yes: 1 }

	validates :user_id, presence: true
	validates :leave_request_id, presence: true
	validates :vote, presence: true

	attr_accessible :vote, :leave_request_id, :comments

	scope :for_user, ->(uid) { where(user_id: uid) }
	scope :for_request, ->(rid) { where(leave_request_id: rid).order(:updated_at) }

  private

  def set_user
    self.user_id = User.current.id
  end

  def set_processing
    if LeaveRequest.where(:id => self.leave_request_id).any?
      req = LeaveRequest.find(self.leave_request_id)
      req.update_attribute(:request_status, "processing")
    end
  end

end