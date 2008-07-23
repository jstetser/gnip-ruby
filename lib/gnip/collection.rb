class Gnip::Collection

  attr_accessor :post_url
  attr_reader :uids, :name

  def initialize(name)
    @name = name
    @uids = []
  end

  def uri
    'collections'
  end

  def add_uid(uid, publisher_name)
    @uids << Gnip::Uid.new(uid, publisher_name)
  end

  def remove_uid(uid, publisher_name)
    @uids.delete(Gnip::Uid.new(uid, publisher_name))
  end

  def to_xml()
    return XmlSimple.xml_out(self.to_hash, {'RootName' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end

  def to_hash()
    result = {}
    result['name'] = @name
    result['postUrl'] = @post_url if @post_url
    result['uid'] = uids.collect { |uid| uid.to_hash()}
    { 'collection' => result }
  end

  def eql?(object)
    self == object
  end

  def ==(object)
    object.instance_of?(self.class) && @name == object.name
  end

  def self.from_hash(hash)
    collection = new(hash['name'])
    collection.post_url = hash['postUrl'] if hash['postUrl']
    uids = hash['uid']
    if uids
      uids.each do |uid_hash|
        collection.adduid(Gnip::Uid.from_hash(uid_hash))
      end
    end
    return collection
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash)
  end

  def adduid(uid)
    @uids << uid
  end

  # Returns a set of activities that occured around a partiular time
  # for this collection.
  #
  # @param [Time] time   The time at which you are interested in the
  #     activities of this collection.  Default: Time.now
  #
  # @return [Array of Gnip::Activities] 
  #
  # @raises [Exception]  If getting the activities does not succeed.
  def activities(time = Time.now)
    logger.debug("Getting activities for #{name} at #{time.to_gnip_bucket_id}")
    
    response, activities_xml = Gnip.connection.get("#{activity_bucket_uri_for(time)}")

    raise GnipRequestError, 
      "Gnip responded to GET request to \"#{activity_bucket_uri_for(time)}\" with a #{response.code} response" unless response.code =~ /^2/
    
    Gnip::Activity.unmarshal_activity_xml(activities_xml)
  end

  # The URI of this collections activity stream.
  def activity_stream_uri
    "/collections/#{name}/activity"
  end
  
  # The URI to a particular activity bucket of this collections
  # activity stream.
  def activity_bucket_uri_for(at_time)
    "/collections/#{name}/activity/#{at_time.to_gnip_bucket_id}.xml"
  end

  private 
  
  # The logger this object should use.
  def logger
    Gnip.logger
  end
end
