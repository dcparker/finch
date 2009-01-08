require 'openid'
require 'openid/store/filesystem'

# Add this to your router.rb:
#   # OpenId
#   r.to(:controller => 'app_openid') do |openid|
#     openid.match('/signin').to(:action => 'signin').name(:signin)
#     openid.match('/start_signin').to(:action => 'start_signin').name(:start_signin)
#     openid.match('/complete_signin').to(:action => 'complete_signin').name(:complete_signin)
#     openid.match("/signout").to(:action => 'signout').name(:signout)
#   end

class AppOpenid < Application
  force(:signin).only('AppOpenid' => [])

  def signin
    render
  end

  def start_signin(openid_url)
    openid_url = OpenIDUrl.new(APP[:default_openid].call(openid_url)).normalized if APP[:default_openid].is_a?(Proc) && openid_url !~ /\./ # Doesn't have periods - it must be simply a nickname. Use the default openid service.
    return redirect(
      begin
        openid_consumer.begin(openid_url).redirect_url( APP[:web_root], abs_url(:complete_signin) )
      rescue OpenID::OpenIDError => e
        presenter.error "The openid_url '#{openid_url}' couldn't be found."
        url(:signin, :login => openid_url)
      end
    )
  end

  # If the openid_url used is not yet in the system, session[:openid_url] will be set, but current_person won't find a person.
  # On the next request the user will be forced over to create a nickname and other info for their person object, and current_person
  # will work after that.
  def complete_signin
    response = openid_consumer.complete(request.send(:query_params), 'http://'+request.host+request.path)
    # SUCCESS, CANCEL, FAILURE, or SETUP_NEEDED
    if response.status.to_s == 'success'
      # The user is now signed in.
      self.current_person = OpenIDUrl.new(response.identity_url).normalized
      return complete_pathway(:signin)
    elsif response.status.to_s == 'cancel'
      presenter.error "Login as #{response.endpoint.claimed_id} was cancelled. Please try again or use a different login."
      return redirect(:signin)
    else
      Merb.logger.info response.inspect
      "FAILED: #{response.respond_to?(:message) ? response.message : response.status}"
      # Failed: The openid_server returned unauthorized, or other error.
      # Be nice to the user and tell them something went wrong. (not in those words)
    end
  end
  
  def signout
    session.delete(:openid_url)
    session.save
    redirect '/'
  end

  protected
    def openid_consumer
      @openid_consumer ||= OpenID::Consumer.new(session, OpenID::Store::Filesystem.new("#{Merb.root}/tmp/openid"))
    end
end

Merb::BootLoader.load_action_arguments(['AppOpenid'])
