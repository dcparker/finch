class Xions < Application
  layout :xions

  def self.klass
    Xion
  end
  provides :xml, :js, :yaml, :json
  
  def index
    as current_user do
      @xions, @total, @limit, @offset = paginated(Xion, params)
    end
    my_render :collection, @xions
  end

  def show
    @xion = my Xion.get!(params[:id])
    my_render :element, @xion
  end

  def new
    only_provides :html
    @xion = Xion.new
    render
  end

  def create
    as current_user do
      @xion = Xion.new(params[:xion])
  # TODO: raising BadRequest with an argument -- I might need to make a new exception that takes an argument that will redirect nicely for html and show the error, or respond bad-request status with the message for other clients.
      @xion.save ||
        raise(BadRequest.new(@xion.errors.full_messages.to_sentence, :template => 'xions/new'))
      html? ?
        redirect(url(:xions)) :
        created_response( url(:xion, @xion), my_render(:element, @xion) )
    end
  end

  def edit
    only_provides :html
    @xion = my Xion.get!(params[:id])
    render
  end

  def update
    @xion = my Xion.get!(params[:id])
    # Done in two steps because .update will always return true unless invalid, whereas .save returns false if the object has not been modified. Here I'll check .dirty? myself.
    @xion.attributes = params[:xion]
# TODO: raising BadRequest with an argument -- I might need to make a new exception that takes an argument that will redirect nicely for html and show the error, or respond bad-request status with the message for other clients.
    !@xion.dirty? || @xion.update ||
      raise(BadRequest.new(@xion.errors.full_messages.to_sentence, :template => 'xions/edit'))
    html? ?
      redirect(url(:xion, @xion)) :
      my_render(:element, @xion)
  end

  def destroy
    @xion = my Xion.get!(params[:id])
# TODO: raising BadRequest with an argument -- I might need to make a new exception that takes an argument that will redirect nicely for html and show the error, or respond bad-request status with the message for other clients.
    @xion.destroy ||
      raise(BadRequest.new(@xion.errors.full_messages.to_sentence))
    html? ?
      redirect(url(:xions)) :
      render(:nothing => 200)
  end

  def deleted
    as current_user, DeletedRecord do
      @xions, @total, @limit, @offset = paginated(DeletedRecord, params.merge(:object_type => 'Xion'))
    end
    my_render :collection, @xions
  end
end
