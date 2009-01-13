class Users < Application
  before :ensure_authenticated, :only => [:login]

  def login
    # if the user is logged in, then redirect them to the home page
    redirect '/'
  end
end
