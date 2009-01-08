# This file contains several little tidbits of magic that I've made to make certain things easier.
# See Object, Class, and Hash for more.
require 'ruby2ruby'
gem 'hash_magic'
require 'hash_magic'

module BlissMagic
  # This will automagically 1) create a table if it doesn't exist, and 2) create a column if it doesn't exist.
  def self.automigrate(*klasses)
    klasses.each do |klass|
      if DataMapper.database.table_exists?(klass.table.name)
        db_cols = {}
        klass.table.database_columns.each {|dbcolumn| db_cols[dbcolumn.name] = dbcolumn}
        klass.table.columns.each do |column|
          # klass.table.columns // klass.table.database_columns
          unless db_cols.has_key?(column.name)
            warn "!! Database table #{klass.table.name} doesn't contain column #{column.name}!"
            # Create the column that is missing. This should work most of the time. And note, it doesn't handle any default values or anything special like that yet.
            database.execute("ALTER TABLE #{klass.table.to_sql} ADD COLUMN #{column.to_sql} #{database.adapter.class::TYPES[column.type]}")
            puts "Created column (using sql 'ALTER TABLE #{klass.table.to_sql} ADD COLUMN #{column.to_sql} #{database.adapter.class::TYPES[column.type]}')."
          end
        end
      else
        puts "Warning: The database did not contain a '#{klass.table.name}' table."
        klass.auto_migrate!
        puts "Created table '#{klass.table.name}'."
      end
    end
  end
end

class Object
  alias :_raw_respond_to? :respond_to?
  # Supports also_be, by pretending the object responds to methods that really the secondary object will respond to.
  def respond_to?(*args)
    return true if self._raw_respond_to?(*args)
    return @also_is.respond_to?(*args) if @also_is
    return false
  end

  # This allows one object to "also be" another object as well. It will sortof act as both, in a way.
  # The original object simply "carries" the secondary object along with it, and any method called on
  # it will be sent to the secondary object. If this creates some unexpected behavior, consider using
  # delegate_methods instead.
  def also_be(object, *with)
    as = with[0].is_a?(Hash) ? with.shift[:as].to_s : 'also_is'
    self.instance_variable_set('@also_is', object)
    self.send(:eval, <<-ddddddd
      def method_missing(method, *args)
        if !@also_is.nil? && @also_is.respond_to?(method)
          @also_is.send(method, *args)
        else
          super
        end
      end
    ddddddd
    )
    self.send(:eval, "def #{as}; @also_is; end")
    self.send(:eval, with.to_a.collect {|method| "def #{method}(*args); @also_is.send(:#{method}, *args); end; "}.join)
  end

  # This allows one to effectively 'proxy' specific methods to be called on the return value of one of its methods.
  # For example, obj.length could be delegated to do the same thing as obj.full_text.length
  def delegate_methods(hsh)
    raise ArgumentError, "delegate_methods should be called like: delegate_methods [:method1, :method2] => :delegated_to_method" unless hsh.is_a?(Hash)
    hsh.keys.each do |methods|
      delegate_to = hsh[methods]
      methods.to_a.each do |method|
        self.send(:eval, <<-ddddddd
          (alias :"_#{method}" :#{method}) if respond_to?(:#{method})
          def #{method}(*args, &block)
            if self.respond_to?(:#{delegate_to})
              block_given? ? self.#{delegate_to}.#{method}(*args, &block) : self.#{delegate_to}.#{method}(*args)
            else
              block_given? ? self.send(:"_#{method}", *args, &block) : self.send(:"_#{method}", *args)
            end
          end
        ddddddd
        )
      end
    end
  end
  def delegate_instance_methods(hsh)
    raise ArgumentError, "delegate_methods should be called like: delegate_methods [:method1, :method2] => :delegated_to_method" unless hsh.is_a?(Hash)
    hsh.keys.each do |methods|
      delegate_to = hsh[methods]
      methods.to_a.each do |method|
        self.send(:class_eval, <<-ddddddd
          alias :"_#{method}" :#{method} if respond_to?(:#{method})
          def #{method}(*args, &block)
            if self.respond_to?(:#{delegate_to})
              block_given? ? self.#{delegate_to}.#{method}(*args, &block) : self.#{delegate_to}.#{method}(*args)
            else
              block_given? ? self.send(:"_#{method}", *args, &block) : self.send(:"_#{method}", *args)
            end
          end
        ddddddd
        )
      end
    end
  end

  # Wraps any non-Array into an array
  def to_a
    self.is_a?(Array) ? self : [self]
  end

  # Normally one would say, "if [:a, :b, :c].include?(:a)" -- which is backward thinking, instead you should use this magic:
  # ":a.is_one_of?(:a, :b, :c)", or :a.is_one_of?([:a, :b, :c]).
  def is_one_of?(*ary)
    ary = ary.first if ary.first.is_a?(Array) && ary.length == 1
    ary.include?(self)
  end
  # The opposite of is_one_of?
  def is_not_one_of?(*ary)
    !is_one_of?(*ary)
  end

  def not_nil?
    !nil?
  end

  # Appends methods to any object that simply return objects.
  def static(hsh)
    hsh.each { |k,v| eval "class << self; def #{k}; #{v.inspect} end end" }
    self
  end

  # # Injects to the named instance variables their new values
  # def iv(hsh)
  #   hsh.each { |k,v| instance_variable_set(:"@#{k}", v)}
  #   self
  # end
  
  # Executes the block in the context of self, then returns self
  def extended(&block)
    block.in_context(self).call
    self
  end
end

class Proc
  # Changes the context of a proc so that 'self' is the klass_or_obj passed.
  # Proc#to_ruby requires ruby2ruby
  def in_context(klass_or_obj)
    klass_or_obj.send(:eval, self.to_ruby)
  end
end

module Kernel
  # Executes a block/proc in the context of the klass_or_obj passed, returning the return value of that block/proc.
  def as(klass_or_obj, *args, &block)
    raise ArgumentError, "must include a block" unless block.is_a?(Proc)
    block.in_context(klass_or_obj).call(args)
  end
end

class Class
  # Returns the class name without the module names that precede it. I'm sure there's a builtin way to do this, but I couldn't find it and this works just as reliably!
  # Examples:
  # - Quickbooks::Qbxml::Request.class_leaf_name # => 'Request'
  # - Quickbooks::Customer.class_leaf_name # => 'Customer'
  def class_leaf_name
    self.name[self.parent.name.length+2,self.name.length-self.parent.name.length-2]
  end
  def delegate_methods(*args)
    delegate_instance_methods(*args)
  end
end

class String
  def self.random(len=nil)
    len = rand(24) unless len
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['-', '_']
    newpass = ''
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    newpass
  end
end

require 'bliss_magic/indifferent_access'
class Hash
  # Transform all the keys in the hash to CamelCase format.
  def camelize_keys!
    self.each_key do |k|
      self[k.camelize] = self.delete(k)
    end
  end

  def crawl(&block)
    raise ArgumentError, "no block given" unless block_given?
    self.each do |k,v|
      case block.arity
      when 1
        yield(v)
      when 2
        yield(k,v)
      when 3
        yield(self,k,v)
        v = self[k]
      end
      if v.is_a?(Array)
        v.crawl(&block)
      elsif v.is_a?(Hash)
        v.crawl(&block)
      end
    end
  end

  # Stringify keys
  def stringify_keys!
    self.each_key do |k|
      self[k.to_s] = self.delete(k)
    end
    self
  end
  def stringify_keys
    {}.merge(self).stringify_keys!
  end

  # Symbolize keys
  def symbolize_keys!
    self.each_key do |k|
      self[k.to_sym] = self.delete(k)
    end
    self
  end
  def symbolize_keys
    {}.merge(self).symbolize_keys!
  end

  def reverse_merge(hsh)
    self.merge(hsh.merge(self))
  end
  def reverse_merge!(hsh)
    self.replace(hsh.merge(self))
  end

  def except(*keys)
    reject {|k,v| keys.flatten.include?(k) }
  end

  # Returns values in this hash that are uniq or different than in the hash provided.
  # Example:
  #   {:a => :b, :f => :g, :z => :e}.diff(:a => :b, :f => :r, :u => :o) # => {:f => :g, :z => :e}
  def diff(hsh)
    dif = {}
    self.each do |k,v|
      dif[k] = v if !hsh.has_key?(k)
      dif[k] = v if hsh[k] != self[k]
    end
    dif
  end

  # Forces the keys in this particular hash to be kept in a static order.
  # You can specify the order when you call order! by sending in an array of sorted keys.
  # Any keys added after this method is called are added on to the end.
  def order!(*keys_in_order)
    @keys_in_order = (keys_in_order.flatten & self.keys).keep_uniq! # (only the keys_in_order that are currently existing keys)
    class << self
      alias :_order_a :[]=
      private :_order_a
      def []=(k,v)
        @keys_in_order << k
        _order_a(k,v)
      end

      def keys
        @keys_in_order
      end
      def values
        self.keys.collect {|k| self[k]}
      end
      def each(&block)
        self.keys.each do |k|
          block.call(k, self[k])
        end
      end
      def each_key(&block)
        self.keys.each &block
      end
      def each_value(&block)
        self.values.each &block
      end
    end
    self
  end

##########################################################
# MAKES HASHES STACKABLE.
# Example:
#   >> j = {:a => :b}
#   => {:a=>:b}
#   >> j.stack!
#   => {:a=>:b}
#   >> j[:b] = 7
#   => 7
#   >> j[24] = 5
#   => 5
#   >> j
#   => {24=>5, :a=>:b, :b=>7}
#   >> j.unstack!
#   => {:a=>:b}
#   >> j.stack!
#   => {:a=>:b}
#   >> j[:a] = 7
#   => 7
#   >> j.unstack!
#   => {:a=>7}
##########################################################
  def blank?
    self.keys.length == 0
  end

  def stack!
    self.add_stack!
  end
  def unstack!
    return self if @last_stack.nil?
    self.replace(@last_stack)
    @last_stack = @last_stack.instance_variable_get('@last_stack')
    self
  end
  def stack!
    @last_stack = self.dup
    self.clear
  end
  alias :_a :[]
  private :_a
  def [](k)
    return _a(k) if @last_stack.nil?
    @last_stack.has_key?(k) ? @last_stack[k] : _a(k)
  end
  alias :_b :[]=
  private :_b
  def []=(k,v)
    return _b(k,v) if @last_stack.nil?
    @last_stack.has_key?(k) ? (@last_stack[k] = v) : _b(k,v)
  end
  alias :_c :keys
  private :_c
  def keys
    return _c if @last_stack.nil?
    (_c + @last_stack.keys).uniq
  end
  alias :_d :has_key?
  private :_d
  def has_key?(k)
    return _d(k) if @last_stack.nil?
    _d(k) || @last_stack.has_key?(k)
  end
  alias :_e :values
  private :_e
  def values
    return _e if @last_stack.nil?
    keys.inject([]) { |values,key| values << self[key] }
  end
  alias :_f :each
  private :_f
  def each(&block)
    return _f(&block) if @last_stack.nil?
    self.keys.each {|k| yield(k,self[k])}
  end
  alias :inspect_top_stack :inspect
  def inspect
    @last_stack.nil? ? inspect_top_stack : flatten.inspect_top_stack
  end
  def flatten
    inject({}) {|h,(k,v)| h[k] = v; h}
  end
##########################################################
# (END STACKABLE)
##########################################################
end

class Array
  def none?(*args)
    !any?(*args)
  end

  def sum(symb=nil)
    total = 0.to_f
    if symb.is_a?(Symbol)
      self.each {|a| total += a.send(symb)}
    else
      self.each {|a| total += a}
    end
    total
  end

  def >>(v)
    self.reject! {|e| e == v}
  end

  # Changes the behavior of a regular expression match, so that instead of true/false (which isn't very useful), it becomes a useful filter as well as a test.
  def =~(v)
    v = v.is_a?(Regexp) ? v : Regexp.new(v)
    # @rejected = self.reject {|e| e =~ v}
    self.reject {|e| e !~ v}
  end

  # Allows you to set a 'live' sorting to an Array
  def auto_sort!(&proc)
    @auto_sort = proc
    class << self
      alias :_a :sort
      private :_a
      def sort(&block)
        block_given? ? _a { |a,b| block.call(a,b) } : _a { |a,b| @auto_sort.call(a,b) }
      end
      alias :_a_ :sort!
      private :_a_
      def sort!(&block)
        block_given? ? _a_ { |a,b| block.call(a,b) } : _a_ { |a,b| @auto_sort.call(a,b) }
      end
      alias :_b :each
      private :_b
      def each(*args,&block)
        sort!
        _b(*args) {|_i_| block.call(_i_)}
      end
      alias :_c :[]
      private :_c
      def [](*args)
        sort!
        _c(*args)
      end
      alias :_c :<<
      private :_c
      def <<(*args)
        sort!
        _c(*args)
      end
      alias :_d :inspect
      private :_d
      def inspect(*args)
        sort!
        _d(*args)
      end
    end
    self
  end

  def last
    self[-1]
  end

  def <<(v)
    (@from_front ? self.unshift(v) : self.push(v)) unless @keep_uniq && self.include?(v)
  end

  def from_front!
    @from_front = true
    self
  end

  def keep_uniq!
    @keep_uniq = true
    self
  end

  def to_sentence(conjunction='and')
    return self[0] if self.length == 1
    self[0...-1].map {|e| e.to_s}.join(', ') + ' ' + conjunction + ' ' + self[-1].to_s
  end

  def highest(symb_or_lambda=nil)
    he = nil
    if symb_or_lambda.is_a?(Symbol)
      h = -1
      self.compact.each do |a|
        t = a.send(symb_or_lambda)
        if t > h
          h = t
          he = a
        end
      end
    elsif symb_or_lambda.is_a?(Proc)
      
    else
      he = -1
      self.compact.each { |a| he = a if a > he }
    end
    he
  end

  def crawl(&block)
    raise ArgumentError, "no block given" unless block_given?
    self.each do |v|
      k = self
      v = case block.arity
      when 1
        yield(v)
      when 2
        yield(k,v)
      when 3
        yield(self,k,v)
      end
      if v.is_a?(Array)
        v.crawl(&block)
      elsif v.is_a?(Hash)
        v.crawl(&block)
      end
    end
  end

  # Very special magic! If you have an array of objects, you can call a method on the array and it will be passed to each element, IF all elements respond to that method.
  def method_missing(sym, *args)
    # If all elements respond to the method, call it on each of them and return an array of the results.
    return self.collect {|e| e.send(sym, *args)} if !self.any? {|e| !e.respond_to?(sym)}
    # To force calling the method even if method_missing doesn't show they all work, or otherwise just for readability, use this instead:
    # [].collect_somethings == [].collect(&:something)
    return self.collect {|e| e.send(Inflector.singularize(sym.to_s.match(/^collect_(.*)/)[1]).to_sym, *args)} if sym.to_s =~ /^collect_(.*)/
    super
  end
end

class DateTime < Date
  delegate_methods :inspect => :to_time

  # Sends missing methods to to_time
  def method_missing(method, *args)
    if respond_to?(:to_time) && to_time.respond_to?(method)
      to_time.send(method, *args)
    else
      super
    end
  end
end

require 'bliss_serializer'
