require 'dm-types'
module MerbPark
  module DM
    module Types

      class StringCollection < DataMapper::Type
        primitive String
        size 65335
        default []

        def self.to_s
          # name.gsub(/.*::/,'')
          'Array'
        end

        def self.load(value, property)
          if value.nil?
            nil
          elsif value.is_a?(String)
            array = ::YAML.load(value)
            MerbPark::Ext::RawCollection.new(@single_klass.to_s, array)
          else
            raise ArgumentError, "+value+ must be nil or a String"
          end
        end

        def self.dump(value, property)
          if value.nil?
            nil
          elsif value.is_a?(String) && value =~ /^---/ # already is yaml
            value
          else
            ::YAML.dump(value) # convert to yaml
          end
        end

        def self.typecast(value, property)
          value
        end
      end

      class LowercaseString < DataMapper::Type
        primitive String

        def self.load(value, property)
          value
        end

        def self.dump(value, property)
          value.to_s.downcase
        end

        def self.typecast(value, property)
          value.to_s.downcase
        end
      end # class LowercaseString

    end
  end
end
