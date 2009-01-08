module TimePointType
  class TimePoint < DataMapper::Type
    primitive String
    size 255

    def self.dump(time_point)
      time_point.to_s
    end

    def self.fetch(raw)
      TimePoint.parse(raw)
    end
  end
end
