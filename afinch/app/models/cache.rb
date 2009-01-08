class Cache
  include DataMapper::Resource
  property :key, String, :key => true
end
