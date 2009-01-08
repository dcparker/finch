class Envelope
  include DataMapper::Resource
  include MoneyType
  property :id, Serial
  belongs_to :user

  property :name, String, :size => 24
  property :type, Enum[:envelope, :checking, :savings, :credit_card], :default => :envelope
  has n, :budgets
  property :actual_amount, Money

  def is_real_account?
    type != :envelope
  end

  def budget
    budgets.first(:effective_start.lte => Time.now, :effective_end.gte => Time.now)
  end
end
