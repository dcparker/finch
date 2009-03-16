begin
  gem 'days_and_times'
rescue
  gem 'dcparker-days_and_times'
end
require 'days_and_times'

# A budget represents a single budgeted period, such as one month or one week, and an amount budgeted for that period.
# A budget for an envelope can change but we still have a history of that envelope's budget.
class Budget
  include DataMapper::Resource
  include MoneyType
  property :id, Serial
  belongs_to :user

  belongs_to :envelope
  property :amount, Money

  property :effective_start, DateTime
  property :effective_end, DateTime
  def effective?(datetime=nil)
    TimePointRange.new(effective_start, effective_end).include?(datetime || Time.now)
  end

  class << self
    def current_period_start(period_size)
      t = Time.now
      case period_size
      when :weekly # Find the beginning of the week
        t.beginning_of_week
      when :biweekly
        t.week % 2 == 1 ? t.beginning_of_week : (t.beginning_of_week - 1.week)
      when :monthly
        t.beginning_of_month
      when :yearly
        t.beginning_of_month.change(:month => 1)
      else
        current_period_start(:monthly)
      end
    end

    def current_period_end(period_size)
      t = Time.now
      case period_size
      when :weekly # Find the beginning of the week
        t.beginning_of_week + 1.week
      when :biweekly
        (t.week % 2 == 1 ? (t + 1.week).beginning_of_week : t.beginning_of_week)
      when :monthly
        t.beginning_of_month + 1.month
      when :yearly
        t.beginning_of_month.change(:month => 1, :year => t.year + 1)
      else
        current_period_end(:monthly)
      end - 1
    end
  end

end
