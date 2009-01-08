module DataMapperExtensions
  def visible_properties(optionals=[])
    optionals = optionals.collect {|e| e.to_s}
    self.class.visible_properties(optionals).reject {|column| column.transparent? ? send(column.name.to_sym).blank? : false}
  end

  module ClassExtensions
    # Make property return the property column as it should.
    def property(name, type, options = {})
      super
      (@properties << table[name])[-1]
    end

    # Designates a method as a private property. This means it will be filtered out of objects being displayed to outside eyes.
    def private_property(name, type=nil, options = {})
      ((type.nil? && table[name]) ? table[name] : property(name, type, options)).extended {@private = true}
    end

    # Designates a property to be an optional property. It is public, but is only included when asked for.
    def optional_property(name, type, options = {})
      property(name, type, options).extended {@optional = true}
    end

    # Designates a property to be a transparent property. It is public, but is only included whenever a value is present, or when requested.
    def transparent_property(name, type, options = {})
      property(name, type, options).extended {@transparent = true}
    end

    def virtual_property(name, &block)
      define_method(name, block) if block_given?
      (@virtual_properties ||= []) << name.to_s.static(:name => name.to_sym, :type => :string, :private? => false, :public? => true, :transparent? => false, :optional? => false)
    end

    def optional_virtual_property(name, &block)
      define_method(name, block) if block_given?
      (@virtual_properties ||= []) << name.to_s.static(:name => name.to_sym, :type => :string, :private? => false, :public? => true, :transparent? => false, :optional? => true).extended {@optional = true}
    end

    def transparent_virtual_property(name, &block)
      define_method(name, block) if block_given?
      (@virtual_properties ||= []) << name.to_s.static(:name => name.to_sym, :type => :string, :private? => false, :public? => true, :transparent? => true, :optional? => false)
    end

    def visible_properties(optionals=[])
      optionals = [optionals] unless optionals.is_a?(Array)
      optionals = optionals.collect {|e| e.to_s}
      (@properties + (@virtual_properties ||= [])).reject {|column| column.private? || (column.optional? ? !optionals.include?(column.name.to_s) : false)}.extended do
        class << self
          alias :_pre_accsss :[]
          def [](name)
            if name.is_a?(Numeric)
              _pre_accsss(name)
            else
              self.reject {|e| e.name.to_s != name.to_s}[0]
            end
          end
        end
      end
    end

    module ColumnExtend
      def private?
        !!@private
      end
      def public?
        !@private
      end
      def transparent?
        !!@transparent
      end
      def optional?
        !!@optional
      end
    end
  end
end

module DataMapper::Adapters::Sql::Mappings
  class Column
    include DataMapperExtensions::ClassExtensions::ColumnExtend
  end
end
