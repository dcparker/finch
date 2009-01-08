class Schedules < Application
  # provides :xml, :yaml, :js

  def index
    @schedules = Schedule.all
    display @schedules
  end

  def show(id)
    @schedule = Schedule.get(id)
    raise NotFound unless @schedule
    display @schedule
  end

  def new
    only_provides :html
    @schedule = Schedule.new
    display @schedule
  end

  def edit(id)
    only_provides :html
    @schedule = Schedule.get(id)
    raise NotFound unless @schedule
    display @schedule
  end

  def create(schedule)
    @schedule = Schedule.new(schedule)
    if @schedule.save
      redirect resource(@schedule), :message => {:notice => "Schedule was successfully created"}
    else
      message[:error] = "Schedule failed to be created"
      render :new
    end
  end

  def update(id, schedule)
    @schedule = Schedule.get(id)
    raise NotFound unless @schedule
    if @schedule.update_attributes(schedule)
       redirect resource(@schedule)
    else
      display @schedule, :edit
    end
  end

  def destroy(id)
    @schedule = Schedule.get(id)
    raise NotFound unless @schedule
    if @schedule.destroy
      redirect resource(:schedules)
    else
      raise InternalServerError
    end
  end

end # Schedules
