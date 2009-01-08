module ExternalIds
  def self.included(base)
    # external_id should be:
    # 1) in the database as private external_ids, with manual serialized structure ';consumer_id1,external_id1;consumer_id2,external_id2;'
    # 2) stored as lazy so it doesn't clutter the records. ? => We can grab it with the record like normal by adding :include in the finder method
    # 3) searched via a finder-method 'external_id' that works per-oauth-consumer
    # 4) accessed and set via a method 'external_id' and 'external_id=' that works per-oauth-consumer
    base.private_property :external_ids, :text #, :lazy => true # text columns are automatically lazy.
    base.transparent_virtual_property :external_id # API will now include the attribute if it has a value -- per oauth consumer. :)
    base.custom_finders(:external_id => ['external_ids LIKE ?', proc {|q| "%;#{Thread.current['oauth_consumer'].id},#{q}%" }])
  end

  def external_id
    if Thread.current['oauth_consumer']
      external_ids_hash[Thread.current['oauth_consumer'].id.to_s]
    else
      nil
    end
  end

  def external_id=(xid)
    if Thread.current['oauth_consumer']
      external_ids_hash[Thread.current['oauth_consumer'].id.to_s] = xid
      @external_ids = ';'+external_ids_hash.map {|k,v| [k,v].join(',')}.join(';')+';'
    else
      false
    end
  end

  private
    def external_ids_hash
      @external_ids_hash ||= external_ids.to_s.split(';').inject({}) do |h,pair|
        k,v = pair.split(',')
        h[k] = v unless k.to_s == ''
        h
      end
    end
end
