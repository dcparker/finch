require 'oauth/server'
require 'oauth_merb_request_proxy'
require 'oauth/signature/hmac/sha1'
require 'bliss_magic'

# Add this to your router.rb:
#   # OAuth Provider
#   r.to(:controller => 'app_oauth') do |oauth|
#     oauth.match('/request_token').to(:action => 'request_token').name(:request_token)
#     oauth.match('/access_token').to(:action => 'access_token').name(:access_token)
#   end

class OauthConsumer < DataMapper::Base
  set_table_name 'oauth_consumers'
  property :callback_url, :string
  property :app_name, :string
  property :consumer_key, :string
  property :consumer_secret, :string
  property :automatic_guid, :string
  property :created_at, :datetime
  property :updated_at, :datetime

  # Generate the keys
  before_create {|rec| rec.regenerate}
  def regenerate!
    self.regenerate.save
    self
  end
  def regenerate
    self.consumer_key = String.random(40)
    self.consumer_secret = String.random(40)
    self
  end

  include Validatable
  validates_presence_of :callback_url
  validates_uniqueness_of :consumer_key
end

class OauthConsumerInstance < DataMapper::Base
  set_table_name 'oauth_consumer_instances'
  property :consumer_id, :integer
  property :request_token, :string
  property :request_secret, :string
  property :access_token, :string
  property :access_secret, :string
  property :person_guid, :string
  property :created_at, :datetime
  property :updated_at, :datetime
  # property :authorized, :boolean

  belongs_to(:person, :primary_key => :guid, :foreign_key => :person_guid)

  def authorized?
    true # You can customize this: The suggested is to use the boolean authorized property. You'll have to write your own authorize method.
  end
end

class Application < Merb::Controller
  private
    def is_oauth?
      @is_oauth ||= !oauth_request.consumer_key.blank? rescue false
    end
    def oauth_request
      @oauth_request ||= OAuth::RequestProxy.proxy(request)
    end
    def oauth_consumer
      return nil if !is_oauth?
      verify_request

      Thread.current['oauth_consumer'] ||= OauthConsumer.first(:consumer_key => oauth_request.consumer_key)
    end
    def oauth_instance
      return nil if !is_oauth?
      verify_request

      @oauth_instance ||= (
          oauth_request.token && (
            OauthConsumerInstance.first(:consumer_id => oauth_consumer.id, :request_token => oauth_request.token) ||
            OauthConsumerInstance.first(:consumer_id => oauth_consumer.id, :access_token => oauth_request.token)
        ) || OauthConsumerInstance.new(:consumer_id => oauth_consumer.id, :person_guid => oauth_consumer.automatic_guid)
      )
      @oauth_instance
    end

    def verify_request
      return nil if !is_oauth?
      return true if @verified || @verifying

      @verifying = true
      raise BadRequest, "Consumer for secret [#{oauth_request.consumer_key}] not available!" unless oauth_consumer
      sig = OAuth::Signature::HMAC::SHA1.new(oauth_request) {|token| [oauth_instance.request_secret || oauth_instance.access_secret, oauth_consumer.consumer_secret] }
      raise BadRequest, "Signature or other parameter not valid." unless oauth_request.signature[0] == sig.signature
      @verifying = false

      @verified = true
    end
end

# == Summary of the Provider ==
# 1) Generates a request_token for the OauthConsumer
# 2) Provides a way for the User to allow or deny access, and on allow, generates an access_token
# 3) Provides the access_token to the OauthConsumer
# 4) Provides data to the OauthConsumer if it provides a valid access_token
class AppOauth < Application
  force(:signin).only('AppOauth' => [])
  before :verify_request

  def register(callback)
    # What do we want to do when we register a consumer? Give them a consumer key right away? Send an email with the key and secret?
  end

  # 1) Generates a request_token for the OauthConsumer
  # First, OAuth consumer site connects here directly to get a request token pair
  # 
  # POST
  def request_token
    # Generate a request_token
    request_token = OAuth::ServerToken.new
    # Save the request_token
    oauth_instance <= {:request_token => request_token.token, :request_secret => request_token.secret}
    # Reply with the request_token
    request_token.to_query
  end

  # Just a suggested method. Make it work whatever way you want.
  # You'll probably want to actually ask the user - this one simply auto-authorizes.
  # The specification suggests redirecting to the consumer's callback_url once the user has responded.
  def authorize
    oauth_instance <= {:authorized => true}
    redirect oauth_consumer.callback_url
  end

  # 4) Provides data to the OauthConsumer if it provides a valid access_token
  # Upon callback, OAuth consumer site connects here directly to exchange
  # the request_token for access_token. Access token is used for all 
  # subsequent API calls done on behalf of this end user.
  # 
  # POST 
  def access_token
    # * * * * * * *
    # THIS IS WHERE you VERIFY that the given request_token is ALLOWED to be granted an access_token!
    if !oauth_instance.authorized?
      # The request_token given was not authorized.
      raise BadRequest, "Unauthorized request_token"
    else
      # Generate an access_token
      access_token = OAuth::ServerToken.new
      # Save the access_token, Nullify the request_token
      oauth_instance <= {:access_token => access_token.token, :access_secret => access_token.secret, :request_token => nil, :request_secret => nil}
      # Reply with the access_token
      access_token.to_query
    end
  end
end

BlissMagic.automigrate(OauthConsumer, OauthConsumerInstance)
Merb::BootLoader.load_action_arguments(['AppOauth'])
