# A budget represents a single budgeted period, such as one month or one week, and an amount budgeted for that period.
# A budget for an envelope can change but we still have a history of that envelope's budget.
class Budget
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user

  belongs_to :envelope
  property :amount, Integer

  property :effective_start, DateTime
  property :effective_end, DateTime
  def effective?(datetime=nil)
    TimePointRange.new(effective_start, effective_end).include?(datetime || Time.now)
  end

end
