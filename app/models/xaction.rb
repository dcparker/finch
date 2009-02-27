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
  property :description, String
  property :date,   DateTime
  property :completed,  Boolean
  property :created_at, DateTime

  validates_with_method :amount, :verify_source_balance, :if => :new_record?
  before :save, :complete_xaction

  def type
    # If it has from, it's a debit; if it has to, it's a credit; if it has both, it's a transfer.
    (from_id.nil? ^ to_id.nil?) ? (to_id.nil? ? :credit : :debit) : :transfer
  end

  private
    def verify_source_balance
      return [false, "There is not enough funds in #{from.name} to take #{amount} out of it."] if new_record? && from && from.actual_amount - amount < 0
      return true
    end

    # Complete or uncomplete transaction.
    # If the move is FROM a real account, don't debit the account until after transaction is completed.
    # If the move is TO an envelope, credit the envelope when transaction is initiated and debit the envelope when completed.
    def complete_xaction
      if valid?
        # For new records, certain types of transactions will be automatically set as completed.
        self.completed = true if new_record? && (to.is_account? && (from_id.nil? || from.is_account?))

        # If amount changes, we have to update the envelope amount if it's still pending; otherwise update just the account amount.
        if !new_record? && dirty_attributes.keys.include?(Xaction.properties[:amount])
          if completed
            # update the debited account
            diff = amount - Xaction.get(id).amount
            from.update_attributes(:actual_amount => from.actual_amount.to_f + diff)
          else
            # update the envelope amount
            diff = amount - Xaction.get(id).amount
            to.update_attributes(:actual_amount => to.actual_amount.to_f + diff)
          end
        end
        
        # Complete/Pending
        if dirty_attributes.keys.include?(Xaction.properties[:completed])
          # Envelope side
          if to && !to.is_account?
            if new_record? && !completed
              # credit the envelope
              to.update_attributes(:actual_amount => to.actual_amount.to_f + amount.to_f)
            end
            if !new_record?
              if completed
                # debit the envelope
                to.update_attributes(:actual_amount => to.actual_amount.to_f - amount.to_f)
                to.budget.update_attributes(:amount => amount.to_f < from.budget.amount.to_f ? to.budget.amount.to_f - amount.to_f : 0) # If spending, take it out of the current budget too.
              else
                # undo the debit
                to.update_attributes(:actual_amount => to.actual_amount.to_f + amount.to_f)
                to.budget.update_attributes(:amount => amount.to_f < to.budget.amount.to_f ? to.budget.amount.to_f + amount.to_f : 0) # If spending, take it out of the current budget too.
              end
            end
          end

          # Debiting from Account
          if from && from.is_account?
            if completed
              # debit the account
              from.update_attributes(:actual_amount => from.actual_amount.to_f - amount.to_f)
            elsif !new_record? && !completed
              # undo the debit
              from.update_attributes(:actual_amount => from.actual_amount.to_f + amount.to_f)
            end
          end

          # Crediting to Account
          if to && to.is_account?
            if completed
              # debit the account
              to.update_attributes(:actual_amount => to.actual_amount.to_f + amount.to_f)
            elsif !new_record? && !completed
              # undo the debit
              to.update_attributes(:actual_amount => to.actual_amount.to_f - amount.to_f)
            end
          end
        end
      end
    end
end
