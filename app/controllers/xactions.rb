class Xactions < Application
  # provides :xml, :yaml, :js

  def index
    @xactions = Xaction.all(:user_id => my(:id))
    display @xactions
  end

  def show(id)
    xaction(id)
    raise NotFound unless @xaction
    display @xaction
  end

  def new
    only_provides :html
    @xaction = Xaction.new
    display @xaction
  end

  def edit(id)
    only_provides :html
    xaction(id)
    raise NotFound unless @xaction
    display @xaction
  end

  def create(xaction)
    @xaction = Xaction.new(xaction.merge(:user_id => my(:id)))
    if @xaction.save
      redirect '/'
    else
      message[:error] = "Xaction failed to be created"
      render :new
    end
  end

  def update(id, xaction)
    xaction(id)
    raise NotFound unless @xaction
    if @xaction.update_attributes(xaction.merge(:user_id => my(:id)))
       redirect resource(@xaction)
    else
      display @xaction, :edit
    end
  end

  def destroy(id)
    xaction(id)
    raise NotFound unless @xaction
    if @xaction.destroy
      redirect resource(:xactions)
    else
      raise InternalServerError
    end
  end

  private
    def xaction(id)
      @xaction = Xaction.first(:id => id, :user_id => my(:id))
    end
end # Xactions
