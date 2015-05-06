class LeaveRequest < ActiveRecord::Base
  unloadable
  include LeavesHolidaysLogic

  default_scope { where.not(request_status: "3").order(from_date: :asc) }
  
  belongs_to :user
  belongs_to :issue
  has_one :leave_status, dependent: :destroy

  before_validation :set_user
  before_update :validate_update

  enum request_status: { created: 0, submitted: 1, processed: 2, cancelled: 3 }
  enum request_type: { am: 0, pm: 1, ampm: 2 }

  validates :from_date, date: true, presence: true
  validates :to_date, date: true, presence: true
  validates :user_id, presence: true
  validates :issue_id, presence: true
  validates :request_type, presence: true
  validates :request_status, presence: true

   validate :validate_set_request_type
   validate :validate_date_period
   validate :validate_issue
   validate :validate_overlaps
   validate :validate_update
   

  attr_accessor :leave_time_am, :leave_time_pm
  attr_accessible :from_date, :to_date, :leave_time_am, :leave_time_pm, :issue_id, :comments, :user_id, :request_type

  scope :for_user, ->(uid) { where(user_id: uid) }

  scope :overlaps, ->(fr, to) { where("(DATEDIFF(from_date, ?) * DATEDIFF(?, to_date)) >= 0", to, fr) }

  scope :created, -> { where(request_status: "0") }

  scope :submitted, -> { where(request_status: "1") }

  scope :processed, -> { where(request_status: "2") }

  scope :coming, -> { where("from_date > ?", Date.today) }

  scope :ongoing, -> { where("from_date <= ? AND to_date >= ?", Date.today, Date.today) }

  scope :accepted, -> { processed.includes(:leave_status).where(leave_statuses: { acceptance_status: "1" }) }

  scope :processable_by, ->(uid) {
    user = User.find(uid)
    submitted_ids = Array.wrap(submitted + processed).map { |a| a.id }
    submitted_ids.delete_if { |id| !LeavesHolidaysLogic.is_allowed_to_manage_status(user, LeaveRequest.find(id).user) }
    find(submitted_ids)
  }

  def has_am?
    return self.request_type == "am" || self.request_type == "ampm"
  end

  def has_pm?
    return self.request_type == "pm" || self.request_type == "ampm"
  end


	private

	def validate_date_period
		if to_date != nil && from_date != nil && to_date < from_date
			errors.add(:base,"The Leave period entered is invalid")
		end

    if to_date != nil && from_date != nil && self.request_type != "ampm" && (to_date - from_date).to_i > 0
      errors.add(:base,"Half day leaves cannot be more than 1 day")
    end
	end

	def validate_issue
		if issue_id != nil && !((LeavesHolidaysLogic.issues_list.collect {|t| t.id }).include?( issue_id))
			errors.add(:issue, "is invalid")
		end
	end

  def validate_set_request_type
    
    self.leave_time_am.to_i == 0 ? (am = 0) : (am = 1)
    self.leave_time_pm.to_i == 0 ? (pm = 0) : (pm = 1)

    if am == 1 && pm == 0
      self.request_type = 0
    elsif am == 0 && pm == 1
      self.request_type = 1
    elsif am == 1 && pm == 1
      self.request_type = 2
    else
      errors.add(:leave_time_am, "is invalid")
      errors.add(:leave_time_pm, "is invalid")
    end
  end

  def set_user
    self.user_id = User.current.id
  end

  def validate_overlaps
    overlaps = LeaveRequest.for_user(self.user_id).overlaps(from_date, to_date).where.not(id: self.id)
    
    overlaps.created.find_each do |p|
      errors.add(:base, "You have a leave overlapping the current one. Id: #{p.id} From: #{p.from_date}, To: #{p.to_date}")
    end

    overlaps.submitted.find_each do |p|
      errors.add(:base, "You have a leave overlapping the current one. Id: #{p.id} From: #{p.from_date}, To: #{p.to_date}")
    end

    overlaps.processed.find_each do |p|
      LeaveStatus.for_request(p.id).accepted.find_each do |a|
        errors.add(:base, "You have a leave overlapping the current one. Id: #{p.id} From: #{p.from_date}, To: #{p.to_date}") 
      end
    end
  end

  def validate_update
    if LeaveRequest.where(id: self.id).processed.exists?
      errors.add(:base, "You cannot update this leave request as it has already been processed") 
    end
  end
	
end
