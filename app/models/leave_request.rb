class LeaveRequest < ActiveRecord::Base
  unloadable
  include LeavesHolidaysLogic
  include LeavesHolidaysDates
  include Redmine::Utils::DateCalculation


  default_scope { where.not(request_status: "3") }
  
  belongs_to :user
  belongs_to :issue
  has_one :leave_status, dependent: :destroy
  has_many :leave_vote, dependent: :destroy

  before_validation :set_user
  before_validation :set_user_preferences
  before_update :validate_update

  enum request_status: { created: 0, submitted: 1, processed: 2, cancelled: 3, processing: 4 }
  enum request_type: { am: 0, pm: 1, ampm: 2 }

  validates :from_date, date: true, presence: true
  validates :to_date, date: true, presence: true
  validates :user_id, presence: true
  validates :issue_id, presence: true
  validates :request_type, presence: true
  validates :request_status, presence: true

  validates :region, presence: true
  validates :weekly_working_hours, presence: true, numericality: true, inclusion: { in: 0..80}
  validates :annual_leave_days_max, presence: true, numericality: true, inclusion: { in: 0..365}

  validates_length_of :comments, :maximum => 255

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

  scope :processing, -> { where(request_status: "4") }

  scope :processed, -> { where(request_status: "2") }

  scope :cancelled, -> { where(request_status: "3") }

  scope :coming, -> { where("from_date > ?", Date.today) }

  scope :finished, -> { where("to_date < ?", Date.today) }

  scope :ongoing_or_finished, -> { where("from_date <= ? OR to_date <= ?", Date.today, Date.today) }  

  scope :ongoing, -> { where("from_date <= ? AND to_date >= ?", Date.today, Date.today) }

  scope :accepted, -> { processed.includes(:leave_status).where(leave_statuses: { acceptance_status: "1" }) }

  scope :processable_by, ->(uid) {
    user = User.find(uid)
    submitted_ids = Array.wrap(submitted + processing + processed).map { |a| a.id }
    submitted_ids.delete_if { |id| !(LeavesHolidaysLogic.has_rights(user, LeaveRequest.find(id).user, [LeaveStatus, LeaveVote], [:create, :update], LeaveRequest.find(id), :or))}
    # find(submitted_ids)
    where(id: submitted_ids)
  }

  scope :viewable_by, ->(uid) {
    user = User.find(uid)
    processed_ids = Array.wrap(processed).map { |a| a.id }
    processed_ids.delete_if { |id| !(LeavesHolidaysLogic.has_rights(user, LeaveRequest.find(id).user, [LeaveStatus], [:read], LeaveRequest.find(id), :or))}
    # find(processed_ids)
    where(id: processed_ids)
  }



  def get_days(arg)
    res = {}
    user = User.find(self.user_id)

    contract_start = LeavesHolidaysLogic.user_params(user, :contract_start_date).to_date
    period = LeavesHolidaysDates.get_contract_period(contract_start)

    case arg
    when :remaining
      res[:start] = period[:start]
      res[:end] = period[:end]
      res[:result] = LeavesHolidaysDates.total_leave_days_remaining(user, res[:start], res[:end])
      return res
    when :accumulated
      res[:start] = period[:start]
      res[:end] = Date.today
      res[:result] = LeavesHolidaysDates.total_leave_days_accumulated(user, res[:start], res[:end])
      return res
    when :taken
      res[:start] = period[:start]
      res[:end] = period[:end]
      res[:result] = LeavesHolidaysDates.total_leave_days_taken(user, res[:start], res[:end])
      return res
    else
      return res
    end
  end

  def has_am?
    return self.request_type == "am" || self.request_type == "ampm"
  end

  def has_pm?
    return self.request_type == "pm" || self.request_type == "ampm"
  end

  def half_day?
    return self.request_type != "ampm"
  end

  def real_leave_days
    return 0.5 if half_day?
    return ((to_date - from_date).to_i + 1)
  end

  def actual_leave_days
    return 0.5 if half_day?

    working_days = (to_date + 1 - from_date).to_i

    real_leave_days.times do |i|
      if (from_date + i).holiday?(region.to_sym) || non_working_week_days.include?((from_date + i).cwday)
        working_days -= 1
      end          
    end

    return working_days
  end

  # Restricts the actual leave days to a given period
  def actual_leave_days_within(from, to)
    if half_day?
      if (from_date <= to && from <= to_date)
        return 0.5
      else
        return 0.0
      end
    end

    working_days = (to_date + 1 - from_date).to_i

    real_leave_days.times do |i|
      end_bound = from_date + i
      # If Not working day
      if (end_bound).holiday?(region.to_sym) || non_working_week_days.include?((end_bound).cwday)
        # Decrement working days count
        working_days -= 1
      else # If working day
        # Remove day anyway if it is not in [from : to range]
        if !(from_date <= to && from <= end_bound) || !(end_bound <= to && from <= to_date)
          working_days -= 1
        end 
      end
    end
    return working_days
  end

	private

	def validate_date_period
    if to_date != nil && from_date != nil
  		if to_date < from_date
  			errors.add(:base,"The end of the leave cannot take place before its beginning")
  		end

      if half_day? && (to_date - from_date).to_i > 0
        errors.add(:base,"Half day leaves cannot be more than 1 day")
      end

      # Forbid the leave creation if it's in the past
      # if to_date != nil && from_date != nil && (from_date < Date.today || to_date < Date.today)
      #   errors.add(:base,"Your leave is in the past")
      # end

      #check leave is not in a week-end or bank holiday

        count = 0

        real_leave_days.ceil.times do |i|
          if (from_date + i).holiday?(region.to_sym) || non_working_week_days.include?((from_date + i).cwday)
            count += 1
          end          
        end

        if count == real_leave_days.ceil
          errors.add(:base,"A leave cannot occur only on bank holiday(s) or non working day(s)")
        end
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

  def set_user_preferences
    user = User.find(user_id)
    user_region = LeavesHolidaysLogic.user_params(user, :region)
    self.region = user_region.to_sym
    self.weekly_working_hours = LeavesHolidaysLogic.user_params(user, :weekly_working_hours)
    self.annual_leave_days_max = LeavesHolidaysLogic.user_params(user, :annual_leave_days_max)
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
