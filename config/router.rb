Merb.logger.info("Compiling routes...")
Merb::Router.prepare do
  # OpenID
  match("/openid/login"   ).to(:controller => :open_id, :action => :login   ).name(:openid)
  match("/openid/register").to(:controller => :open_id, :action => :register).name(:signup)

  # Resources
  resources :envelopes do
    member :spend
    member :deposit
    member :withdraw
    member :budget
  end
  resources :xactions
  resources :budgets
  resources :schedules

  # Home
  match('/').to(:controller => "dash")
end
