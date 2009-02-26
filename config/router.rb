Merb.logger.info("Compiling routes...")
Merb::Router.prepare do
  # OpenID
  match("/openid/login"   ).to(:controller => :users,   :action => :login   ).name(:openid)
  match("/openid/register").to(:controller => :open_id, :action => :register).name(:signup)

  # Resources
  resources :envelopes do
    member :spend
    member :deposit
    member :withdraw
    member :budget
    member :add_transaction
    member :show_transactions
  end
  resources :xactions
  resources :budgets
  resources :schedules

  match('/dialogs/:dialog_name').to(:controller => :dash, :action => :show_dialog)

  # Home
  match('/').to(:controller => "dash")
end
