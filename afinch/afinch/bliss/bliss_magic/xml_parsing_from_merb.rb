require 'rexml/light/node'

# This is a slighly modified version of the XMLUtilityNode from
# http://merb.devjavu.com/projects/merb/ticket/95 (has.sox@gmail.com)
# It's mainly just adding vowels, as I ht cd wth n vwls :)
# This represents the hard part of the work, all I did was change the underlying
# parser
class REXMLUtilityNode # :nodoc:
  attr_accessor :name, :attributes, :children
  
  def initialize(name, attributes = {})
    @name       = name.tr("-", "_")
    @attributes = undasherize_keys(attributes)
    @children   = []
    @text       = false
  end
  
  def add_node(node)
    @text = true if node.is_a? String
    @children << node
  end
  
  def to_hash
    if @text
      return { name => typecast_value( translate_xml_entities( inner_html ) ) }
    else
      #change repeating groups into an array
      # group by the first key of each element of the array to find repeating groups
      groups = @children.group_by{ |c| c.name }
      
      hash = {}
      groups.each do |key, values|
        if values.size == 1
          hash.merge! values.first
        else
          hash.merge! key => values.map { |element| element.to_hash[key] }
        end
      end
      
      # merge the arrays, including attributes
      hash.merge! attributes unless attributes.empty?
      
      { name => hash }
    end
  end
  
  def typecast_value(value)
    return value unless attributes["type"]
    
    case attributes["type"]
      when "integer"  then value.to_i
      when "boolean"  then value.strip == "true"
      when "datetime" then ::Time.parse(value).utc
      when "date"     then ::Date.parse(value)
      else                 value
    end
  end
  
  def translate_xml_entities(value)
    value.gsub(/&lt;/,   "<").
          gsub(/&gt;/,   ">").
          gsub(/&quot;/, '"').
          gsub(/&apos;/, "'").
          gsub(/&amp;/,  "&")
  end
  
  def undasherize_keys(params)
    params.keys.each do |key, vvalue|
      params[key.tr("-", "_")] = params.delete(key)
    end
    params
  end
  
  def inner_html
    @children.join
  end
  
  def to_html
    "<#{name}#{attributes.to_xml_attributes}>#{inner_html}</#{name}>"
  end
  
  def to_s 
    to_html
  end
end
