module DataMapper
  module Associations
    module FreeReference
      def initialize(instance, association)
        @instance, @association = instance, association
        @instance.loaded_associations << self
      end
  
      def association
        @association
      end
    end

    class HasManyAssociation
      class FreeSet < Set
        include FreeReference

        def dup
          self.class.new(@instance, @association)
        end

        def items
          @items || begin
            if @instance.loaded_set.nil?
              @items = []
            else              
              associated_items = fetch_sets
              primary_key_ivar_name = association.primary_key_column.instance_variable_name

              # Just set them for this object, not the others
              set(associated_items[@instance.instance_variable_get(association.primary_key_column.instance_variable_name)])

              return @items
            end # if @instance.loaded_set.nil?
          end # begin
        end # def items

        def find(finder_options={})
          primary_key_ivar_name = association.primary_key_column.instance_variable_name
          foreign_key_ivar_name = association.foreign_key_column.instance_variable_name
          
          return dup if @instance.loaded_set.nil?
          finder_options.merge!(association.foreign_key_column.to_sym => @instance.instance_variable_get(primary_key_ivar_name))
          finder_options.merge!(association.finder_options)

          associated_items = @instance.database_context.all(
            association.associated_constant,
            finder_options
          ).group_by { |entry| entry.instance_variable_get(foreign_key_ivar_name) }

          # This is where @items is set, by calling association=,
          # which in turn calls HasManyAssociation::Set#set.
          dadup = dup
          dadup.set(associated_items[@instance.instance_variable_get(association.primary_key_column.instance_variable_name)])
          return dadup
        end

        # A rewrite of the original, because the original was destroying the whole association. This will never do that.
        def save_without_validation(database_context)
          adapter = @instance.database_context.adapter
          
          unless @items.nil? || @items.empty?
            primary_key_value = @instance.instance_variable_get(association.primary_key_column.instance_variable_name)
            foreign_key_ivar_name = association.foreign_key_column.instance_variable_name
            @items.each do |item|
              item.instance_variable_set(foreign_key_ivar_name, primary_key_value)
              @instance.database_context.adapter.save_without_validation(database_context, item)
            end
          end
        end
      end
    end
  end

  class Base
    def associated_records(options)
      DataMapper::Associations::HasManyAssociation::FreeSet.new(
        self,
        DataMapper::Associations::HasManyAssociation.new(self.class, :utterly_nameless, options)
      )
    end

    def associated_record(options)
      DataMapper::Associations::HasOneAssociation::FreeSet.new(
        self,
        DataMapper::Associations::HasManyAssociation.new(self.class, :utterly_nameless, options)
      )
    end
  end
end
