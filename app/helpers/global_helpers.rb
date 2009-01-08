module Merb
  # helpers defined here available to all views.  
  module GlobalHelpers
    # TODO: Add callbacks to make this look like a money field with a dollar sign, etc.
    def money_field(*args)
      text_field *args
    end
  end
end
