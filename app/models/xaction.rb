# A Xaction is made to or from an envelope.
# When a Xaction is made TO an envelope, the amount is added onto the envelope's amount.
# When a Xaction is made FROM an envelope, the amound is deducted from the envelope's amount AND budget.
class Xaction
  include DataMapper::Resource
  include MoneyType
  property :id, Serial
  belongs_to :user

  belongs_to :from, :class_name => 'Envelope', :child_key => [:from_id]
  belongs_to :to,   :class_name => 'Envelope', :child_key => [:to_id]
  property :amount, Money
  property :created_at, DateTime

  validates_with_method :amount, :verify_source_balance, :if => :new_record?
  after :create, :update_envelope_balances

  def type
    # If it has from, it's a debit; if it has to, it's a credit; if it has both, it's a transfer.
    (from_id.nil? ^ to_id.nil?) ? (to_id.nil? ? :credit : :debit) : :transfer
  end

  private
    def verify_source_balance
      return [false, "There is not enough funds in #{from.name} to take #{amount} out of it."] if new_record? && from && from.actual_amount - amount < 0
      return true
    end
    def update_envelope_balances
      if from
        from.budget.update_attributes(:amount => amount < from.budget.amount.to_f ? from.budget.amount.to_f - amount : 0) unless to # If spending, take it out of the current budget too.
        from.update_attributes(:actual_amount => from.actual_amount.to_f - amount)
      end
      to.update_attributes(:actual_amount => to.actual_amount.to_f + amount) if to
    end
end
