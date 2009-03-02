class Users < Application
  before :auto_login if Merb.env == 'development'
  before :ensure_authenticated

  def login
    # if the user is logged in, then redirect them to the home page
    redirect '/'
  end
end
