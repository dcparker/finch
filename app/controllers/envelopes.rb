class Envelopes < Application
  # provides :xml, :yaml, :js

  def index
    @envelopes = Envelope.all(:user_id => my(:id))
    display @envelopes
  end

  def show(id)
    envelope(id)
    raise NotFound unless @envelope
    display @envelope
  end

  def new
    only_provides :html
    @envelope = Envelope.new
    display @envelope, params[:layout] == 'modal' ? {:layout => 'modal'} : {}
  end

  def edit(id)
    only_provides :html
    envelope(id)
    raise NotFound unless @envelope
    display @envelope
  end

  def create(envelope)
    @envelope = Envelope.new(envelope.merge(:user_id => my(:id)))
    if @envelope.save
      redirect '/'
    else
      message[:error] = "Envelope failed to be created"
      render :new
    end
  end

  def spend(id)
    envelope(id)
    @xaction = Xaction.new(:from_id => id)
    render :layout => 'modal'
  end
  def deposit(id)
    envelope(id)
    @xaction = Xaction.new(:to_id => id)
    render :layout => 'modal'
  end
  def withdraw(id)
    envelope(id)
    @xaction = Xaction.new(:from_id => id)
    render :layout => 'modal'
  end
  def budget(id)
    envelope(id)
    render :layout => 'modal'
  end

  def update(id, envelope)
    envelope(id)
    raise NotFound unless @envelope
    if @envelope.update_attributes(envelope.merge(:user_id => my(:id)))
       redirect resource(@envelope)
    else
      display @envelope, :edit
    end
  end

  def destroy(id)
    envelope(id)
    raise NotFound unless @envelope
    if @envelope.destroy
      redirect resource(:envelopes)
    else
      raise InternalServerError
    end
  end

  private
    def envelope(id)
      @envelope = Envelope.first(:id => id, :user_id => my(:id))
    end
end # Envelopes
