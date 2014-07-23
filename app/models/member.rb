# TODO: Add job which puts time into time_banks for maternity and hold members
class Member < ActiveRecord::Base
  MEMBERSHIP_FEE = 50
  INVESTMENT_FEE = 25
  FULL_NAME      = 'LTRIM(CONCAT_WS(" ", first_name, middle_name, last_name)) AS full_name'
  cattr_reader :genders, :statuses, :contact_preferences
  @@genders  = %w[Male Female]
  @@statuses = %w[active inactive suspended hold parental canceled interested volunteer]
  @@contact_preferences = %w[email phone]

  has_many :committees,   dependent: :restrict_with_exception
  has_many :fees,         dependent: :restrict_with_exception do
    include Fee::MemberProxy
  end
  has_many :furloughs,    dependent: :restrict_with_exception
  has_many :holds,        dependent: :restrict_with_exception
  has_many :parentals,    dependent: :restrict_with_exception
  has_many :time_banks,   dependent: :restrict_with_exception do
    include TimeBank::MemberProxy
  end

  has_many :fee_notes
  has_many :furlough_notes
  has_many :member_notes
  has_many :notes
  has_many :time_bank_notes

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, email: { mx: true, message: "Host does not receive email" }, if: lambda {|m| m.contact_preference == "email" }
  validates :gender, inclusion: { in: @@genders }, allow_nil: true, allow_blank: true
  validates :status, inclusion: { in: @@statuses }, allow_nil: true, allow_blank: true
  validates :contact_preference, inclusion: { in: @@contact_preferences }, allow_nil: true, allow_blank: true
  validates :monthly_hours, numericality: { greater_than: 0.0 }
  validates :membership_discount, numericality: { greater_than_or_equal_to: 0.0 }
  validates :investment_discount, numericality: { greater_than_or_equal_to: 0.0 }

  scope     :form_select, -> { full_name.select(:id) }
  scope     :full_name,   -> { select(FULL_NAME) }

  def membership_rate
    MEMBERSHIP_FEE - (MEMBERSHIP_FEE * membership_discount / 100.0)
  end

  def investment_rate
    INVESTMENT_FEE - (INVESTMENT_FEE * membership_discount / 100.0)
  end

  def membership_in(type = :weeks)
    return 0.0 unless join_date?

    since = (Date.current - join_date).to_f
    case type
    when :days    then since
    when :weeks   then since / 7.0
    when :months  then since / 30.0
    when :years   then since / 365.0
    end.floor
  end

  def work_in(type = :weeks)
    return 0.0 unless work_date?

    since = (Date.current - work_date).to_f
    case type
    when :days    then since
    when :weeks   then since / 7.0
    when :months  then since / 30.0
    when :years   then since / 365.0
    end.floor
  end

  def hours_owed
    work_in(:months) * monthly_hours
  end

  def full_name
    read_attribute(:full_name) || [first_name, middle_name, last_name].join(' ')
  end

  def membership_status(force = false)
    return @membership_status if @membership_status && !force

    @membership_status = Struct::MembershipStatus.new(
      status,                                     # status
      join_date,                                  # join_date
      false,                                      # can_shop
      (holds.active.first.finish rescue nil),     # hold
      fees.membership_paid?,                      # membership_fees
      fees.membership_balance,                    # membership_fees_balance
      fees.membership_payment_overdue?,           # membership_fees_overdue
      (parentals.active.first.finish rescue nil), # parental
      time_banks.balance,                         # time_bank_balance
    )
  end

  # JSON work around
  def can_shop
    can_shop?
  end

  def can_shop?
    membership_status(true).can_shop?
  end

  def can_shop_messages
    membership_status.messages
  end

  def update_status(new_status)
    update_columns(status: new_status) if status != new_status
  end
end
