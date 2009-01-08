class User
  include DataMapper::Resource
  include MerbAuth::Adapter::DataMapper
  include MerbPark::DM::Types # make LowercaseString available
  attr_accessor :password, :password_confirmation
  property :id,                         Integer,  :serial   => true
  include MerbPark::Acl::Agent
  property :login,                      LowercaseString, :format => /^[a-z_]{6,}$/, :nullable => false, :length => 3..40, :unique => true, :unique_index => true
  property :email,                      String,   :nullable => false, :unique => true
  property :created_at,                 DateTime
  property :updated_at,                 DateTime
  property :activated_at,               DateTime
  property :activation_code,            String
  property :crypted_password,           String
  property :salt,                       String
  property :remember_token,             String
  property :remember_token_expires_at,  DateTime
  property :password_reset_key,         String,   :writer => :protected

  validates_is_unique     :password_reset_key,  :if => :password_reset_key
  validates_present       :password,            :if => :password_required?
  validates_is_confirmed  :password,            :if => :password_required?

  before :valid? do
    set_login
  end
  before :save,   :encrypt_password
  before :create, :make_activation_code
  after  :create, :send_signup_notification

  # after :valid?, :log_object_error; def log_object_error; puts "Object: #{inspect}\nError: #{errors.full_messages.join(', ')}" if !errors.empty? end
end
