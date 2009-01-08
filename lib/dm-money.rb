module MoneyType
  class Money < DataMapper::Type
    primitive Integer

    def self.dump(value, property)
      (value.to_f * 100).to_i
    end

    def self.load(value, property)
      value.to_f / 100
    end

    def self.typecast(value, property)
      value.to_f
    end
  end
end

class Float
  def to_money
    "%.2f" % self
  end
end
