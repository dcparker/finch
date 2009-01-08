module Bliss
  module TracksDeleted
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def tracks_deleted
        before_destroy do |rec|
          DeletedRecord.create(
            :object_type => rec.class.name,
            :object_id => rec.id,
            :expires_guid => rec.guid,
            :external_id => rec.external_id,
            :created_at => rec.created_at,
            :deleted_at => Time.now,
            :created_by => rec.created_by,
            :person_guid => rec.respond_to?(:person_guid) ? rec.person_guid : nil,
            :person_id => rec.respond_to?(:person_id) ? rec.person_id : nil
          )
        end
      end
    end
  end
end

class DeletedRecord < DataMapper::Base
  set_table_name 'deleted_records'
  private_property :object_id, :integer
  property :expires_guid, :string
    xml_options[:key_name] = :expires_guid
  property 'object_type', :string
  property 'created_by',  :string # string instead of symbol won't trigger the magic for the created_by field. I think.
  private_property :person_id, :integer
  property :person_guid, :string
  property :external_id, :string
  property :created_at, :datetime
  property :deleted_at, :datetime
  as(table) { @paranoid = false }
  
  custom_finders  :deleted_after => 'deleted_at > ?',
                  :deleted_before => 'deleted_at < ?',
                  :self => 'expires_guid = ?'

  include OrmAuthorization
  readable {|me| {:created_by => me}}
  authorize_read {|deleted, me| deleted.created_by == me}
  authorize_update {|deleted, me| deleted.created_by == me}
  authorize_destroy {|deleted, me| deleted.created_by == me}
end

BlissMagic.automigrate(DeletedRecord)
DataMapper::Base.send(:include, Bliss::TracksDeleted)
