require 'bliss_serializer'
require 'free_associations'

module Bliss
  class WhereCondition
    def initialize(klass, *args)
      @klass = klass
      @args = args
    end

    def update!(attrs={})
      # Update all in one sql command without respecting callbacks.
    end

    def destroy!
      # Destroy all in one sql command without respecting callbacks.
    end

    def method_missing(method, *args)
      set.collect {|rec| rec.send(method, *args)}
    end

    def set
      ([] + @klass.all(*@args)).freeze
    end
  end
end

module DataMapperExtensions
  def self.included(base)
    base.extend ClassExtensions
  end

  module ClassExtensions
    def any?(*args)
      self.first(*args).nil? ? false : true
    end
    def none?(*args)
      !any?(*args)
    end

    def where(*args)
      Bliss::WhereCondition.new(self, *args)
    end

    def delegate_key_accessor_to(att)
      class_eval("def self.[](#{att}_or_id); #{att}_or_id.is_a?(String) && #{att}_or_id !~ /^\\d+$/ ? self.first(:#{att} => #{att}_or_id) : self.first(#{att}_or_id) end")
    end

    def xml_options
      (@xml_options ||= {}).reverse_merge!(DataMapper::Support::Serialization::XML_OPTIONS)
    end
  end

  # DataMapper doesn't have id=, but we can instead raise an error for the cases where we really shouldn't be trying to set the id.
  def id=(v)
    raise RuntimeError, "can't set an id to an already-existing object!" if @id || @new_record == false
    @new_record = false
    @id = v
  end

  def <=(attrs)
    raise ArgumentError, "arguments to <= must be a hash of attributes, or an object that responds to .attributes with a hash" unless attrs.is_a?(Hash) || (attrs.respond_to?(:attributes) && attrs.attributes.is_a?(Hash))
    o_att = {}
    (attrs.is_a?(Hash) ? attrs : attrs.attributes).each_pair do |key, value|
      if respond_to?("#{key}=")
        send("#{key}=", value)
      else
        o_att[key] = value
      end
    end
    self.update_attributes(o_att)
    self
  end

  def exists?
    self.class.first(self.class.table.key.name => self.id) ? true : false
  end
  alias :existing? :exists?
  alias :exist? :exists?

  def error?
    !errors.blank?
  end
end

# Add the magical property :created_by => (local_openid_url)
DataMapper::Persistence::ClassMethods::MAGIC_PROPERTIES[:created_by] = lambda { before_create { |rec| rec.created_by ||= Person.current_guid } }

module DataMapper
  class Base
    include DataMapperExtensions
  end

  # to_xml, to_hash for datamapper objects
  module Support
    module Serialization
      HASH_OPTIONS = {
        :include_key => true,
        :instance_columns => :visible_properties,
        :class_columns => :visible_properties,
      }
      XML_OPTIONS = {
        :include_key => :attribute, # Can be false, :element, or :attribute
        :report_nil => false, # Sets an attribute nil="true" on elements that are nil, so that the reader doesn't read as an empty string
        :key_name => :self, # Default key name
        :instance_columns => :visible_properties,
        :class_columns => :visible_properties,
      }
      def xml_options
        (@xml_options ||= {}).reverse_merge!(self.class.xml_options)
      end
      def to_xml(options={})
        to_xml_document(options)
      end
      # Casts a DataMapper object to xml, in the fashion I want.
      def to_xml_document(options={})
        raise ArgumentError, "options must be a hash" unless options.is_a?(Hash)
        options.merge!(Thread.current['symbolized_params'].only(:include)) if options.empty? && Thread.current['symbolized_params'].is_a?(Hash)

        Serialize.object_to_xml(self,xml_options.merge(options))
      end
      # This is where all the property magic comes in:
      # 1) NEVER reveal private properties.
      # 2) Include ALL public properties, real or virtual.
      # 3) Include transparent properties when they contain a value.
      # 4) Include optional properties, real or virtual, when asked for.
      def to_hash(options={})
        options = HASH_OPTIONS.merge(options)
        includes_flat_ary = {'include' => options[:include]}.slashed['include'] || []
        includes_flat_ary = includes_flat_ary.to_string_array if includes_flat_ary.is_a?(SlashedHash)
        includes = includes_flat_ary.collect {|e| e.gsub(/\/.*/,'')}.uniq
        (respond_to?(options[:instance_columns]) ? send(options[:instance_columns], includes) : self.class.send(options[:class_columns], includes)).uniq.inject({}.slashed) do |hsh,column|
          # We are cycling through the list of public real and virtual properties, plus valid requested properties (valid = must be declared optional).
          attr_method = column.type == :boolean ? column.name.to_s.ensure_ends_with('?') : column.name
          if respond_to?(attr_method) && (options[:include_key] || !column.key?)
            vals = includes_flat_ary.reject {|e| e !~ Regexp.new("^#{column.name.to_s}(?:/|$)")}.collect {|e| e.gsub(Regexp.new("^#{column.name.to_s}(?:/|$)"),'')}
            if vals.empty?
              hsh[column.name] = send(attr_method)
            else
              val = send(attr_method)
              hsh[column.name] = SlashedHash.new(vals.collect {|e| val[e]})
            end
          end
          hsh
        end
      end
    end

    module CollectionSerialization
      def to_xml(options={})
        raise ArgumentError, "options must be a hash" unless options.is_a?(Hash)
        options.merge!(Thread.current['symbolized_params'].only(:include, :exclude)) if options.empty? && Thread.current['symbolized_params'].is_a?(Hash)

        class_name = self.respond_to?(:association) ? self.association.associated_constant_name : self.class.name

        doc = REXML::Document.new
        collection_root = self.length == 1 ? doc : doc.add_element(Inflector.pluralize(Inflector.underscore(class_name)))
        self.each do |element|
          collection_root << REXML::Document.new(Serialize.object_to_xml(element, (element.respond_to?(:xml_options) ? element.xml_options : {}).merge(options)).to_s)
        end
        doc.to_s
      end
    end
  end

  module Associations
    # Includes the CollectionSerialization for all Association collections automatically
    class Reference
      include Support::CollectionSerialization
    end

    class HasNAssociation
      # Adds the :lambda option which can be called to dynamically add conditions to a pre-made search (primarily for dynamic associations).
      def finder_options
        finder_opts = (@finder_options || @finder_options = @options.reject { |k,v| self.class::OPTIONS.include?(k) }).dup
        finder_opts.merge!(finder_opts.delete(:lambda).call) if finder_opts[:lambda].is_a?(Proc)
        finder_opts
      end
    end
  end

  # The DataMapper Collection Object
  # + Acts like an array, EXCEPT:
  # + Can ONLY hold datamapper objects inside
  # + Adds a few methods: to_xml, to_json
  class Collection < Array
    include Support::CollectionSerialization

    def initialize(*args)
      @klass = args.pop if args[-1].is_a?(Class)
      super(*args)
      validate!(self)
    end

    def <<(v)
      super if validate!(v)
    end
    def push(v)
      super if validate!(v)
    end
    def unshift(v)
      super if validate!(v)
    end

    # Pretend I'm the class of all my children.
    alias :collection_class :class
    def class
      @klass || self[0].class
    end

    private
      def validate!(values)
        values = [values] unless values.is_a?(Array)
        raise TypeError, "DataMapper::Collection can only contain persistent objects all of the same persistent class." if values.any? {|e| !e.class.persistent? && e.class == self.class}
      end
  end

  class Context
    def all(klass, options = {})
      DataMapper::Collection.new(@adapter.load(self, klass, options), klass)
    end
  end
end
class Array
  def to_datamapper_collection
    DataMapper::Collection.new(self)
  end
end
