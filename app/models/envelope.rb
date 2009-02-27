class Envelope
  include DataMapper::Resource
  include MoneyType
  property :id, Serial
  belongs_to :user

  property :name, String, :size => 24
  property :type, Enum[:envelope, :cash, :checking, :savings, :credit_card], :default => :envelope
  has n, :budgets
  property :budget_period, Enum[:weekly, :biweekly, :monthly, :yearly], :default => :monthly
  property :actual_amount, Money
  property :deleted_at, ParanoidDateTime

  def is_account?
    type != :envelope
  end

  def budget
    @budget ||= (Budget.first(:envelope_id => id, :effective_start.lte => Time.now, :effective_end.gte => Time.now) || Budget.new(:envelope_id => id, :user_id => user_id, :amount => 0.0, :effective_start => Budget.current_period_start(budget_period), :effective_end => Budget.current_period_end(budget_period)))
  end

  def amount_available
    @amount_available ||= is_account? ? Money.new((Xaction.all(:from_id => id, :completed => false).inject(actual_amount) {|sum,x| sum = sum - x.amount} * 100).to_i) : actual_amount
  end
end
