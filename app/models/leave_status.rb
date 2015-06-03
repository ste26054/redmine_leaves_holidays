class LeaveStatus < ActiveRecord::Base
  unloadable
  include Redmine::Utils::DateCalculation

  default_scope { where.not(acceptance_status: "2").order(updated_at: :desc) }
  
  belongs_to :user
  belongs_to :leave_request

  before_destroy :set_submitted
  before_validation :set_user
  after_commit :update_log_time
  after_save :send_notifications


  enum acceptance_status: { rejected: 0, accepted: 1, cancelled: 2 }

  validates :user_id, presence: true
  validates :leave_request_id, presence: true
  validates :acceptance_status, presence: true

  attr_accessible :acceptance_status, :leave_request_id, :comments

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

  def update_log_time
    request = LeaveRequest.find(self.leave_request_id)
    user = User.find(request.user_id)
    hours_per_day = LeavesHolidaysLogic.user_params(user, :weekly_working_hours).to_f / (7.0 - non_working_week_days.count )
    
    if request.half_day?
      hours_per_day /= 2.0
    end

    request.real_leave_days.ceil.times do |i|
      unless (request.from_date + i).holiday?(request.region.to_sym) || non_working_week_days.include?((request.from_date + i).cwday)
        begin
          time_entry = TimeEntry.where(:issue_id => request.issue_id, 
                                                :spent_on => request.from_date + i, 
                                                :user => user).first

          if time_entry != nil && (acceptance_status == "cancelled" || acceptance_status == "rejected")
            time_entry.destroy!
          end

          if time_entry == nil && acceptance_status == "accepted"
            time_entry = TimeEntry.new(:issue_id => request.issue_id, 
                                                  :spent_on => request.from_date + i,
                                                  :activity => TimeEntryActivity.find(RedmineLeavesHolidays::Setting.defaults_settings(:default_activity_id)),
                                                  :hours => hours_per_day,
                                                  :comments => request.comments, 
                                                  :user => user)
            time_entry.save!
          end
        end
      end          
    end
  end

  def send_notifications
    changes = self.changes
    if RedmineLeavesHolidays::Setting.defaults_settings(:email_notification).to_i == 1
      if changes.has_key?("acceptance_status")
        if changes["acceptance_status"][1] == "rejected"
          
        end
        if changes["acceptance_status"][1] == "accepted"

        end
        if changes["acceptance_status"][1] == "cancelled"

        end
      end
    end
  end

  def vote_list_left
    return LeavesHolidaysLogic.vote_list_left(self.leave_request)
  end

  def manage_list
    return LeavesHolidaysLogic.manage_list(self.leave_request)
  end

end
