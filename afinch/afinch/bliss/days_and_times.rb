require 'time'

class Duration
  # Length is the length of the time span, in seconds
  # Unit is a length of time (in seconds) to use in collection methods
  # StartTime is an optional attribute that can 'anchor' a duration
  #   to a specific real time.
  attr_accessor :length, :unit, :start_time
  def initialize(count=0,unit=1,start_time=nil,auto_klass={})
    if unit.is_a?(Time) || unit.is_a?(DateTime)
      start_time = unit
      unit = 1
    end
    options = {:count => count || 0, :unit => unit || 1, :start_time => start_time}.merge(count.is_a?(Hash) ? count : {})

    @unit = options[:unit]
    @length = (@unit * options[:count].to_f).round
    @start_time = options[:start_time]
  end
  def self.new(*args)
    a = super
    if self.name == 'Duration' && (args.last.is_a?(Hash) ? args.last[:auto_class] == true : true)
      a.send(:auto_class)
    else
      a
    end
  end
  def self.length
    1
  end

  # * * * * * * * * * * * * * * * *
  # A Duration is a LENGTH of Time
  #   -This is measured in seconds,
  #    but set in terms of the unit
  #    currently being used.
  def length=(value)
    if value.respond_to?(:to_f)
      @length = (self.unit * value.to_f).round
    else
      raise TypeError, "Can't set a Duration's length to a #{value.class.name} object."
    end
  end
  def length
    @length.to_f / self.unit
  end
  def abs_length=(value)
    if value.respond_to?(:to_i)
      @length = value.to_i
    else
      raise TypeError, "Can't set a Duration's length to a #{value.class.name} object."
    end
  end
  def abs_length
    @length
  end
  def to_i
    self.abs_length.to_i
  end
  def to_f
    self.abs_length.to_f
  end
  def coerce(*args)
    to_f.coerce(*args)
  end
  # * * * * * * * * * * * * * * * *

  # * * * * * * * * * * * * * * * * * * * * *
  # A Duration's calculations utilize a UNIT
  #   -This is stored as the number of
  #    seconds equal to the unit's value.
  def unit=(value)
    if value.respond_to?(:to_i)
      @unit = value.to_i
    else
      raise TypeError, "Can't set a Duration's unit to a #{value.class.name} object."
    end
  end
  def -(value)
    if value.respond_to?(:to_i)
      auto_class(Duration.new(@length - value.to_i))
    else
      raise TypeError, "Can't convert #{value.class.name} to an integer."
    end
  end
  def +(value)
    if value.respond_to?(:to_i)
      auto_class(Duration.new(@length + value.to_i))
    else
      raise TypeError, "Can't convert #{value.class.name} to an integer."
    end
  end
  def *(value)
    if value.is_a?(Duration)
      @length * value.length * value.unit
    elsif value.respond_to?(:to_i)
      auto_class(Duration.new(@length * value))
    else
      raise TypeError, "Can't convert #{value.class.name} to an integer."
    end
  end
  def /(value)
    if value.is_a?(Duration)
      @length / (value.length * value.unit)
    elsif value.respond_to?(:to_i)
      auto_class(Duration.new(@length / value))
    else
      raise TypeError, "Can't convert #{value.class.name} to an integer."
    end
  end
  def in_weeks
    self.unit = Week.length
    auto_class(self)
  end
  def in_days
    self.unit = Day.length
    auto_class(self)
  end
  def in_hours
    self.unit = Hour.length
    auto_class(self)
  end
  def in_minutes
    self.unit = Minute.length
    auto_class(self)
  end
  def in_seconds
    self.unit = Second.length
    auto_class(self)
  end
  def weeks
    @length.to_f / Week.length
  end
  def days
    @length.to_f / Day.length
  end
  def hours
    @length.to_f / Hour.length
  end
  def minutes
    @length.to_f / Minute.length
  end
  def seconds
    @length.to_f / Second.length
  end
  # * * * * * * * * * * * * * * * * * * * * *

  # * * * * * * * * * * * * * * * * * * * * * * *
  # A Duration can be 'anchored' to a START_TIME
  #   -This start_time is a Time object
  def start_time=(value)
    if value.is_a?(Time) || value.is_a?(DateTime)
      @start_time = value.to_time
    else
      raise TypeError, "A Duration's start_time must be a Time or DateTime object."
    end
  end
  def end_time=(value)
    if value.is_a?(Time) || value.is_a?(DateTime)
      @start_time = value.to_time - self #Subtracts this duration from the end_time to get the start_time
    else
      raise TypeError, "A Duration's end_time must be a Time or DateTime object."
    end
  end
  def end_time
    @start_time + self
  end
  def anchored?
    !self.start_time.nil?
  end
  # * * * * * * * * * * * * * * * * * * * * * * *

  # * * * * * * * * * * * * * * * * * * * * * * * *
  # Calculations using Duration as an intermediate
  def from(time)
    time + @length
  end
  def before(time)
    time - @length
  end
  def from_now
    self.from(Now)
  end
  def ago
    self.before(Now)
  end
  def starting(time)
    self.start_time = time
    self
  end
  def ending(time)
    self.end_time = time
    self
  end
  # * * * * * * * * * * * * * * * * * * * * * * * *

  # * * * * * * * * * * * * * * * * * * * * * * * * * * *
  # A Duration can be treated as a 'collection' of units
  def each_week(&block)
    self.each(Week.length,&block)
  end
  def each_day(&block)
    self.each(Day.length,&block)
  end
  def each_hour(&block)
    self.each(Hour.length,&block)
  end
  def each_minute(&block)
    self.each(Minute.length,&block)
  end
  def each_second(&block)
    self.each(Second.length,&block)
  end
  def collect(use_unit=self.class.length,&block)
    ary = []
    self.each(use_unit) do |x|
      ary << (block_given? ? yield(x) : x)
    end
    ary
  end
  def each(use_unit=self.class.length)
    (@length.to_f / use_unit).ceil.times do |i|
      yield self.start_time.nil? ? Duration.new(1, use_unit) : Duration.new(1, use_unit, (self.start_time + (use_unit * i)))
    end
  end
  # * * * * * * * * * * * * * * * * * * * * * * * * * * *

  # * * * * * * * * * * * * * * * * * * * * * * * * * * *
  # Through some ingenious metacoding (see 'def bind_object_method') below,
  # it is possible to create a new method on a Duration object
  # to a method on another object, in order to gather information
  # based on the duration mentioned.
  def create_find_within_method_for(other, method_name, other_method_name)
    self.bind_object_method(other, method_name, other_method_name, [[], ['self.start_time', 'self.end_time']])
  end
  # * * * * * * * * * * * * * * * * * * * * * * * * * * *

  def method_missing(method_name, *args)
    # Delegate any missing methods to the start_time Time object, if we have a start_time and the method exists there.
    return self.start_time.send(method_name, *args) if self.anchored? && self.start_time.respond_to?(method_name)
    super
  end

  private
    def auto_class(obj=self)
      case obj.unit
      when 1
        obj.class == 'Seconds'  ? obj : (obj.length == 1 ? Second.new(obj.start_time) : Seconds.new(obj.length,obj.start_time))
      when 60
        obj.class == 'Minutes'  ? obj : (obj.length == 1 ? Minute.new(obj.start_time) : Minutes.new(obj.length,obj.start_time))
      when 3600
        obj.class == 'Hours'    ? obj : (obj.length == 1 ? Hour.new(obj.start_time) : Hours.new(obj.length,obj.start_time))
      when 86400
        obj.class == 'Days'     ? obj : (obj.length == 1 ? Day.new(obj.start_time) : Days.new(obj.length,obj.start_time))
      when 604800
        obj.class == 'Weeks'    ? obj : (obj.length == 1 ? Week.new(obj.start_time) : Weeks.new(obj.length,obj.start_time))
      else
        obj.class == 'Duration' ? obj : Duration.new(obj.length,obj.unit,obj.start_time,{:auto_class => false})
      end
    end
end
class Weeks < Duration
  def initialize(count=1,start_time=nil)
    super(count,Week.length,start_time)
  end
  def self.length
    604800
  end
end
class Week < Weeks
  def initialize(start_time=nil)
    super(1,start_time)
  end
end
class Days < Duration
  def initialize(count=1,start_time=nil)
    super(count,Day.length,start_time)
  end
  def self.length
    86400
  end
end
class Day < Days
  def initialize(start_time=nil)
    super(1,start_time)
  end
end
class Hours < Duration
  def initialize(count=1,start_time=nil)
    super(count,Hour.length,start_time)
  end
  def self.length
    3600
  end
end
class Hour < Hours
  def initialize(start_time=nil)
    super(1,start_time)
  end
end
class Minutes < Duration
  def initialize(count=1,start_time=nil)
    super(count,Minute.length,start_time)
  end
  def self.length
    60
  end
end
class Minute < Minutes
  def initialize(start_time=nil)
    super(1,start_time)
  end
end
class Seconds < Duration
  def initialize(count=1,start_time=nil)
    super(count,Second.length,start_time)
  end
  def self.length
    1
  end
end
class Second < Seconds
  def initialize(start_time=nil)
    super(1,start_time)
  end
end

class Numeric
  def weeks
    self == 1 ? Week.new : Weeks.new(self)
  end
  def week
    self.weeks
  end

  def days
    self == 1 ? Day.new : Days.new(self)
  end
  def day
    self.days
  end

  def hours
    self == 1 ? Hour.new : Hours.new(self)
  end
  def hour
    self.hours
  end

  def minutes
    self == 1 ? Minute.new : Minutes.new(self)
  end
  def minute
    self.minutes
  end

  def seconds
    self == 1 ? Second.new : Seconds.new(self)
  end
  def second
    self.seconds
  end

  def is_multiple_of?(num)
    (self.to_f / num.to_f).to_i.to_f == (self.to_f / num.to_f)
  end
end

module YannoStringExt
  def self.included(base)
    base.send :alias_method, :to_primitive_time, :to_time if String.respond_to?(:to_time)
    base.send :alias_method, :to_time, :to_smart_time
  end

  # * * * * * * * * * * * *
  # I'm trying to redo this to allow things like '9:30'.to_time, giving the current day at 9:30am
  # This method was stolen from and replaces :to_time rails/activesupport/lib/active_support/core_ext/string/conversions.rb
  def to_smart_time(form = :utc)
# 1) Research parsedate to see how it's parsing
# 2) Refacter the parse to insert the current values from the top down,
#    as they don't exist. Ignore seconds completely unless given by the string.
    ::Time.send("#{form}_time", *ParseDate.parsedate(self)[0..5].map {|arg| arg || 0})
  end
end
String.send :include, YannoStringExt

class Time
  # Returns a new Time where one or more of the elements have been changed according to the +options+ parameter. The time options
  # (hour, minute, sec, usec) reset cascadingly, so if only the hour is passed, then minute, sec, and usec is set to 0. If the hour and
  # minute is passed, then sec and usec is set to 0.
  def change(options)
    ::Time.send(
      self.utc? ? :utc_time : :local_time,
      options[:year]  || self.year,
      options[:month] || self.month,
      options[:day]   || options[:mday] || self.day, # mday is deprecated
      options[:hour]  || self.hour,
      options[:min]   || (options[:hour] ? 0 : self.min),
      options[:sec]   || ((options[:hour] || options[:min]) ? 0 : self.sec),
      options[:usec]  || ((options[:hour] || options[:min] || options[:sec]) ? 0 : self.usec)
    )
  end

  def day_name
    self.strftime("%A")
  end
  def month_name
    self.strftime("%B")
  end

  # Seconds since midnight: Time.now.seconds_since_midnight
  def seconds_since_midnight
    self.to_i - self.change(:hour => 0).to_i + (self.usec/1.0e+6)
  end

  # Returns a new Time representing the start of the day (0:00)
  def beginning_of_day
    (self - self.seconds_since_midnight).change(:usec => 0)
  end
  alias :midnight :beginning_of_day
  alias :at_midnight :beginning_of_day
  alias :at_beginning_of_day :beginning_of_day

  # Returns a new Time if requested year can be accomodated by Ruby's Time class
  # (i.e., if year is within either 1970..2038 or 1902..2038, depending on system architecture);
  # otherwise returns a DateTime
  def self.time_with_datetime_fallback(utc_or_local, year, month=1, day=1, hour=0, min=0, sec=0, usec=0)
    ::Time.send(utc_or_local, year, month, day, hour, min, sec, usec)
  rescue
    offset = if utc_or_local.to_sym == :utc then 0 else ::DateTime.now.offset end
    ::DateTime.civil(year, month, day, hour, min, sec, offset, 0)
  end

  def self.local_time(*args)
    time_with_datetime_fallback(:local, *args)
  end

  def self.tomorrow
    Time.now.beginning_of_day + 1.day
  end
  def tomorrow
    self.beginning_of_day + 1.day
  end
  def self.yesterday
    Time.now.beginning_of_day - 1.day
  end
  def yesterday
    self.beginning_of_day - 1.day
  end
  def self.today
    Time.now.beginning_of_day
  end
  def until(end_time)
    Duration.new(end_time - self, self)
  end
  def through(duration)
    self.until(duration)
  end
  def for(duration)
    raise TypeError, "must be a Duration object." unless duration.is_a?(Duration)
    duration.start_time = self
    duration
  end
  def is_today?
    self.beginning_of_day == Time.today
  end
  def strfsql
    self.strftime("%Y-#{self.strftime("%m").to_i.to_s}-#{self.strftime("%d").to_i.to_s}")
  end
  def self.from_tzid(tzid) #We aren't handling the Time Zone part here...
     if tzid =~ /(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)Z/ # yyyymmddThhmmss
       Time.xmlschema("#{$1}-#{$2}-#{$3}T#{$4}:#{$5}:#{$6}")
     else
       return nil
     end
  end
  def humanize_time
    self.strftime("%M").to_i > 0 ? self.strftime("#{self.strftime("%I").to_i.to_s}:%M%p").downcase : self.strftime("#{self.strftime("%I").to_i.to_s}%p").downcase
  end
  def humanize_date(length_profile='medium') #There may be decent reason to change how this works entirely...
    case length_profile
    when 'abbr' || 'abbreviated'
      self.strftime("%m/%d/%y")
    when 'short'
      self.strftime("%b #{self.strftime("%d").to_i.to_s}")
    when 'medium'
      self.strftime("%B #{self.strftime("%d").to_i.to_s}")
    when 'long'
      self.strftime("%B #{self.strftime("%d").to_i.to_s}, %Y")
    end
  end
  def humanize_date_time
    self.humanize_date + ' ' + self.humanize_time
  end
end

class Object
  def bind_class_object_method(other, self_method_name, other_method_name, args=[[],[]])
    # Since I can't pass the 'other' object into eval as a string, I have to
    #   set a class instance variable and copy the contents to a class variable
    #   so that the generated method will play nicely with subclasses.
    self.instance_variable_set("@#{self_method_name.to_s}_OBJ", other)
    self.send :eval, "@@#{self_method_name.to_s}_OBJ = @#{self_method_name.to_s}_OBJ
    def #{self_method_name.to_s}(#{args[0].join(', ')})
      @@#{self_method_name.to_s}_OBJ.#{other_method_name.to_s}(#{args[1].join(', ')})
    end"
    self
  end
  def bind_object_method(other, self_method_name, other_method_name, args=[[],[]])
    self.instance_variable_set("@#{self_method_name}_OBJ", other)
    eval "def self.#{self_method_name}(#{args[0].join(', ')})
      @#{self_method_name}_OBJ.#{other_method_name}(#{args[1].join(', ')})
    end"
  end
end

module Kernel
  def Now
    Time.now
  end
  def Today
    Time.today
  end
  def Tomorrow
    Time.tomorrow
  end
  def Yesterday
    Time.yesterday
  end
end
