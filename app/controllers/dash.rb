class Dash < Application
  before :ensure_authenticated

  def index
    render
  end

  def show_dialog
    send(params[:dialog_name]) if private_methods.include?(params[:dialog_name])
    render(params[:dialog_name].to_sym, :layout => 'dialog')
  end

  def template
    partial "templates/#{params[:template_name]}"
  end

  private
    def new_transaction
      from_id = params[:from_id].to_s.gsub(/\D/,'').to_i
      to_id = params[:to_id].to_s.gsub(/\D/,'').to_i
      envs = Envelope.all(:id => [from_id, to_id].reject {|i| i==0})
      @from = envs.select {|e| e.id == from_id}[0]
      @to = envs.select {|e| e.id == to_id}[0]
    end

    def view_pending_transactions
      new_transaction
      filter = {:completed => false}
      filter[:to_id] = @to.id if @to
      filter[:from_id] = @from.id if @from
      @xactions = Xaction.all(filter) || []
      puts "Xactions: #{@xactions.inspect}"
    end
end
