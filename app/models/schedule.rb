class Schedule
  include DataMapper::Resource
  include TimePointType
  property :id, Serial
  belongs_to :user

  belongs_to :envelope

  property :schedule, TimePoint
  property :budget_amount, Integer

  property :effective_start, DateTime
  property :effective_end, DateTime
  def effective?(datetime=nil)
    TimePointRange.new(effective_start, effective_end).include?(datetime || Time.now)
  end
end
