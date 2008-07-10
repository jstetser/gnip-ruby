class Gnip::Publisher
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def uri
    'publishers'
  end

  def to_xml()
    return XmlSimple.xml_out(self.to_hash, {'RootName' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end

  def to_hash()
    result = {}
    result['name'] = @name
    { 'publisher' => result }
  end

  def ==(object)
    object.instance_of?(self.class) && @name == object.name
  end
  alias :eql? :==

  def self.from_hash(hash)
    return Gnip::Publisher.new(hash['name'])
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash)
  end

  # To Publish activities to gnip you must be the owner of the publisher.
  #
  # @param [Enumerable] activities -- A collection of activities to
  #   publish to Gnip.
  #
  # @raise [PublishingError]  Raised if the publish does not succeed for any reason.
  def publish(activities)
    Gnip.logger.info("Publishing #{activities.size} activities for #{name}")
    response = Gnip.connection.post(path, Gnip::Activity.list_to_xml(activities))

    raise PublishingError, "Server returned #{response.code} response." unless response.code =~ /^2\d{2}/
  end

  

  private

  def path
    "/publishers/#{name}/activity"
  end
end
