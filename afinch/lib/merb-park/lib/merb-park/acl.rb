module MerbPark
  module Acl
    class AclString < DataMapper::Type
      primitive String
      size 128

      class << self
        def load(string, property)
          new string
        end

        def dump(acl, property)
          acl.to_s
        end

        def typecast(value, property)
          value.is_a?(AclString) ? value : AclString.new(value)
        end
      end

      # Behavior of the AclString...

      def initialize(string)
      end

      # Acl permissions act just like unix permissions.
      # Has three sections: owner, groups, permissions
      def owner
      end
      def groups
      end

      # Can check if this object has permission to :action that object
      def create?(acl)
        true
      end
      def create?(acl)
        true
      end
      def update?(acl)
        true
      end
      def delete?(acl)
        true
      end
    end # class AclString

    # Include this in a DataMapper::Resource that should be treated as a user that can have permission to operate on other objects.
    module Agent
      def self.included(base)
        base.property :acl, AclString
      end
      def owner
        acl.owner
      end
      def groups
        acl.groups
      end
      def permission_to?(action, object)
        raise ArgumentError unless [:create, :read, :update, :delete].include?(action)
        # You have permission if the object doesn't require permissions
        true if !object.respond_to?(:acl)
        # Otherwise, check the permissions of the object
        self.acl.send(:"#{action}?", object.acl)
      end
    end # module AclAgent

    # Include this in a DataMapper::Resource that should be treated as an object that needs permission to be operated on.
    module Resource
      def self.included(base)
        base.property :created_by, String
        # base.define_method(:save_creator) do
        #   created_by = current_user
        # end
        # base.before :create, :save_creator
        base.property :acl, AclString
      end
      def owner
        acl.owner
      end
      def groups
        acl.groups
      end
    end # module Object
  end # module Acl
end # module MerbPark
