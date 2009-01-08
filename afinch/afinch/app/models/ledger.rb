class Ledger < DataMapper::Base
  property :name, :string, :key => true
  property :last_transaction_time, :datetime
  property :amount, :integer

  property :user_id, :integer
  belongs_to :user

  def to_s
    name
  end
  
  def self.by_name(name)
    self.first(:name => name) || self.create(:name => name, :last_transaction_time => Time.now, :amount => 0)
  end

  # Add a transaction to the ledger
  def +(trans)
    (self.amount = self.amount + trans.amount.to_i).to_s == '0' ? self.destroy! : self.save
  end

  # Subtract a transaction from the ledger
  def -(trans)
    (self.amount = self.amount - trans.amount.to_i).to_s == '0' ? self.destroy! : self.save
  end
end

BlissMagic.automigrate(Ledger)
