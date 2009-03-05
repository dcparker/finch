module MoneyType
  class Money < DataMapper::Type
    primitive Integer

    # Putting the value into the database
    def self.dump(value, property)
      value.to_i
    end

    # Taking a value from the database
    def self.load(value, property)
      Money.new(value.to_i)
    end

    # Setting a value into the object
    def self.typecast(value, property)
      Money.new((value.to_f * 100).round)
    end

    def initialize(integer)
      @value = integer
    end

    def to_s
      @value < 0 ? '-' : '' + case
      when @value.abs > 99
        @value.to_s[0..-3] + '.' + @value.to_s[-2..-1]
      when @value.abs > 0
        '.' + @value.abs.to_s
      else
        @value.abs.to_s
      end
    end

    def to_i
      @value
    end

    def to_f
      @value.to_f / 100
    end

    def method_missing(name, *args)
      puts "Method: #{name}, #{args.join(', ')}"
      if to_f.respond_to?(name)
        to_f.send(name, *args)
      else
        super
      end
    end
  end
end
