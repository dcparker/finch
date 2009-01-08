require 'rexml/light/node'
require 'rexml/document'
gem 'formattedstring'
require 'formatted_string'
require 'bliss_magic/xml_parsing_from_merb'
module Serialize
  XML_OPTIONS = {
    :include_key => false, # Can be false, :element, or :attribute
    :report_nil => true, # Sets an attribute nil="true" on elements that are nil, so that the reader doesn't read as an empty string
    :key_name => :id, # Default key name
    :instance_columns => :visible_properties,
    :class_columns => :visible_properties,
    :default_root => 'xml',
  }
  def self.object_to_xml(obj, options={})
    # Automatically set the key_name for DataMapper objects
    # options.merge!(:key_name => obj.class.table.key.name) if obj.class.respond_to?(:table) && obj.class.respond_to?(:persistent?) && obj.class.persistent?
    # Cast to xml. obj.to_hash will take care of including the right attributes with the :include option.
    options = options.reverse_merge!(obj.class.xml_options) if obj.class.respond_to?(:xml_options)
    options = options.reverse_merge!(obj.xml_options) if obj.respond_to?(:xml_options)
    to_xml(obj.to_hash(options), {:root => Inflector.underscore(obj.class.name)}.merge(options))
  end
  def self.to_xml(attributes={}, options={})
    options = XML_OPTIONS.merge(options)
    root = options[:root]
    attributes = attributes.except(*([options[:exclude]].flatten.compact))

    doc = REXML::Document.new
    root_element = doc.add_element(root || 'xml')

    case options[:include_key]
    when :attribute
      root_element.add_attribute(options[:key_name].to_s, attributes.delete(options[:key_name].to_s).to_s).extended do
        def self.to_string; %Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"] end
      end
    when :element
      root_element.add_element(options[:key_name].to_s) << REXML::Text.new(attributes.delete(options[:key_name].to_s).to_s)
    end

    attributes.each do |key,value|
      if value.nil?
        node = root_element.add_element(key.to_s)
        node.add_attribute('nil', 'true') if options[:report_nil]
      else
        if value.respond_to?(:to_xml)
          assoc_options = {}
          assoc_options = {:exclude => value.association.foreign_key_column.name} if value.respond_to?(:association)
          root_element.add_element(REXML::Document.new(value.to_xml(assoc_options.merge(:root => key)).to_s))
        else
          root_element.add_element(key.to_s) << REXML::Text.new(value.to_s.dup)
        end
      end
    end

    root ? doc.to_s : doc.children[0].children.to_s
  end
  
  def self.hash_from_xml(xml,options={})
    xml.formatted(:xml).to_hash
  end
end

class Hash
  def to_xml(options={})
    options[:root] = keys.length == 1 ? keys[0] : nil if !options.has_key?(:root)
    Serialize.to_xml(self.slashed, options.merge(:root => (options.has_key?(:root) ? options[:root] : 'xml')))
  end
end

class Array
  def to_xml(options={})
    collect {|e| e.to_xml(options)}.join('')
  end
end

# Adds the DoXmlFormat for ActiveResource xml parsing.
# Use it by specifying self.format = :do_xml in your model.
module ActiveResource
  module Formats
    module DoXmlFormat
      XML_OPTIONS = {
        :include_key => :element, # Can be false, :element, or :attribute
        :report_nil => false, # Sets an attribute nil="true" on elements that are nil, so that the reader doesn't read as an empty string
        :key_name => :id, # Default key name
      }
      extend self
      
      def extension
        "xml"
      end
      
      def mime_type
        "application/xml"
      end
      
      def encode(hash,options={})
        hash.reject {|k,v| k.to_s == XML_OPTIONS[:key_name].to_s}.to_xml(options)
      end
      
      def decode(xml)
# puts "XML: #{xml}"
        get_attributes(Serialize.hash_from_xml(xml,XML_OPTIONS))
      end
      
      private
        # Manipulate from_xml Hash, because xml_simple is not exactly what we
        # want for ActiveResource.
        def get_attributes(data)
          # Usually this will be the case, as xml is supposed to have ONE root element.
          data = (data.is_a?(Hash) && data.keys.size == 1) ? data.values.first : data
          # If it is a collection, the root will have been a plural containing several singles.
          data = (data.is_a?(Hash) && data.keys.size == 1) ? data.values.first : data
# puts "Data: #{data.inspect}"

          data
        end      
    end
  end

  class Base
    def to_xml(options={})
      self.class.format.name == 'ActiveResource::Formats::DoXmlFormat' ? self.class.format.encode(attributes, :root => self.class.element_name) : attributes.to_xml({:root => self.class.element_name}.merge(options))
    end
  end
end

module Merb
  class Request
    def xml_params
      @xml_params ||= begin
        if Merb::Const::XML_MIME_TYPE_REGEXP.match(content_type)
          Serialize.hash_from_xml(raw_post) rescue Mash.new
        end
      end
    end
  end
end
