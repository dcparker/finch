module MerbPark
  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def scoped(query)
        with_scope(query) { yield }
      end
    end
  end
end
