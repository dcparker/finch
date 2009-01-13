class Budgets < Application
  # provides :xml, :yaml, :js

  def index
    @budgets = Budget.all
    display @budgets
  end

  def show(id)
    @budget = Budget.get(id)
    raise NotFound unless @budget
    display @budget
  end

  def new
    only_provides :html
    @budget = Budget.new
    display @budget
  end

  def edit(id)
    only_provides :html
    @budget = Budget.get(id)
    raise NotFound unless @budget
    display @budget
  end

  def create(budget)
    @budget = Budget.new(budget)
    if @budget.save
      redirect resource(@budget), :message => {:notice => "Budget was successfully created"}
    else
      message[:error] = "Budget failed to be created"
      render :new
    end
  end

  def update(id, budget)
    @budget = Budget.get(id)
    raise NotFound unless @budget
    if @budget.update_attributes(budget)
       redirect '/'
    else
      display @budget, :edit
    end
  end

  def destroy(id)
    @budget = Budget.get(id)
    raise NotFound unless @budget
    if @budget.destroy
      redirect resource(:budgets)
    else
      raise InternalServerError
    end
  end

end # Budgets
