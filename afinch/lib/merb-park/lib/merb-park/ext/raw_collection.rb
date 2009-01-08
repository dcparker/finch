module MerbPark
  module Ext
    class RawCollection < Array
      def initialize(type, *args)
        @type = type
        super(*args)
      end

      attr_reader :type
      def xml_element_name
        type
      end
  
      protected

      def to_xml_document(opts={}, root=nil)
        root ||= REXML::Document.new
        # root.attributes["type"] = 'array'
        each do |item|
          item.send(:to_xml_document, opts, root)
        end
        root
      end
    end
  end
end
