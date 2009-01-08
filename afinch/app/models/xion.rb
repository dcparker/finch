class Xion
  include DataMapper::Resource
  include MerbPark::DM::Types
  include MerbPark::Model
  property :id,         Serial
  property :amount,     Integer
  property :from,       String
  property :to,         String
  property :description,String
  property :tags,       StringCollection
  property :created_at, DateTime
  include MerbPark::Acl::Resource

  def self.recent
    all(:limit => 20, :order => [:created_at.desc])
  end

  def movement
    case
    when to && from
      "from '#{from}' to '#{to}'"
    when to
      "into '#{to}'"
    when from
      "out of '#{from}'"
    else
      "[unknown]"
    end
  end
end
