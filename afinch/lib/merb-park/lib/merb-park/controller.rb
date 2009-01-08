require 'dm-aggregates' # Includes the Model.count method and more
module MerbPark
  module Controller

    private

    def created_response(location, body)
      set_status(201)
      headers['Location'] = location
      body
    end

    def my_render(type, objects)
      html? ?
        display(objects) :
        display(objects)
        # TODO: wrap_layout(render(objects, :layout => false), :layout => type)
    end

    def paginated(klass, finder_options={})
      # Limit the finder_options to only what the klass can handle.
      finder_options = finder_options.only(klass.properties.collect {|p| p.name.to_s})
      limit = (params[:limit] || params[:"max-results"] || (html? ? 10 : 50)).to_i
      offset = (params[:offset] || params[:"start-index"] || 0).to_i
      objects = klass.all(finder_options.merge('limit' => limit, 'offset' => offset))
      total   = klass.count(finder_options)
      [objects, total, limit, offset]
    end

    def html?
      content_type == :html
    end

    def my(*objects)
      # raise NotAuthorized unless objects.all? {|object| current_user.permission_to?(:read, object)}
      objects.length > 1 ? objects : objects[0]
    end

    def my_scope(klass=nil)
      klass ||= self.class.klass
      if klass.properties.collect {|p| p.name}.include?(:created_by)
        as current_user { yield }
      else
        yield
      end
    end

    def as(user, klass=nil)
      klass ||= self.class.klass
      if klass.properties.collect {|p| p.name}.include?(:created_by)
        klass.scoped(:created_by => user.login) { yield }
      else
        yield
      end
    end
  end
end
