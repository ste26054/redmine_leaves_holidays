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

	after_save :send_notifications

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

  # TO CHECK
  def send_notifications
    changes = self.changes
    if RedmineLeavesHolidays::Setting.defaults_settings(:email_notification).to_i == 1
      if changes.has_key?("vote")
        user_list = []
        user_list = (self.leave_request.manage_list + self.leave_request.vote_list).collect{ |e| e.first[:user]}.uniq
        
        if user_list.empty? || LeavesHolidaysLogic.should_notify_plugin_admin(self.leave_request.user, 3)
            user_list += LeavesHolidaysLogic.plugin_admins_users
        end

        user_list = user_list - [self.user] - [leave_request.user]

        Mailer.leave_vote_mail(user_list, self.leave_request, {user: self.user, vote: self}).deliver

      end
    end
  end

end