require 'pathname'
require Pathname(__FILE__).dirname + '../ext/time'

class Gnip::Connection < Gnip::Base
  include Gnip

  def initialize(config)
    super(config)
  end

  def server_time
    result = head("/")
    Time.httpdate(result['Date']).gmtime
  end

  #Publish a activity xml document to gnip for a give publisher
  #You must be the owner of the publisher to publish
  #activities_xml is the xml stream of gnip activities
  def publish_xml(publisher, activity_xml)
    @gnip_config.logger.info("Publishing activities for #{publisher.name}")
    publisher_path = "/publishers/#{publisher.name}/activity"
    post(publisher_path, activity_xml)
  end

  #Publish a activity xml document to gnip for a give publisher
  #You must be the owner of the publisher to publish
  #activity_list is an array of activity objects
  def publish(publisher, activity_list)
    @gnip_config.logger.info("Publishing activities for #{publisher.name}")
    publisher_path = "/publishers/#{publisher.name}/activity"
    post(publisher_path, Gnip::Connection.list_to_xml(activity_list))
  end

  # Gets the current activities
  # Resource is a publisher or collection resource
  # Time is the time object. If nil, then the server returns the current bucket
  def activities_stream_xml(resource, time = nil)
    timestamp = time ? time.to_gnip_bucket_id : 'current'
    @gnip_config.logger.info("Timestamp for #{time} is #{timestamp}")
    @gnip_config.logger.info("Getting activities xml for #{resource.name} at #{timestamp}")
    get("/#{resource.uri}/#{resource.name}/activity/#{timestamp}.xml")
  end

  # Gets the current activities
  # Resource is a publisher or collection resource
  # Time is the time object. If nil, then the server returns the current bucket
  def activities_stream(resource, time = nil)
    timestamp = time ? time.to_gnip_bucket_id : 'current'
    @gnip_config.logger.info("Timestamp for #{time} is #{timestamp}")
    @gnip_config.logger.info("Getting activities for #{resource.name} at #{timestamp}")
    response, activities_xml = get("/#{resource.uri}/#{resource.name}/activity/#{timestamp}.xml")
    activities = []
    activities = Gnip::Connection.list_from_xml(activities_xml) if response.code == '200'
    [response, activities]
  end

  def get_collection(collection_name)
    @gnip_config.logger.info("Getting collection #{collection_name}")
    find_path = "/collections/#{collection_name}.xml"
    response, data = get(find_path)
    collection = nil
    if (response.code == '200')
      collection = Gnip::Collection.from_xml(data)
    end
    return [response, collection]
  end

  def get_publisher(publisher_name)
    @gnip_config.logger.info("Getting publisher #{publisher_name}")
    get_path = "/publishers/#{publisher_name}.xml"
    response, data = get(get_path)
    publisher = nil
    if (response.code == '200')
      publisher = Gnip::Publisher.from_xml(data)
    end
    return [response, publisher]
  end

  def get_publishers()
    @gnip_config.logger.info('Getting publisher list')
    get_path = '/publishers.xml'
    response, data = get(get_path)
    publishers = []
    if (response.code == '200')
      publishers = Gnip::Connection.publishers_from_xml(data)
    end
    return [response, publishers]
  end

  def create(resource)
    @gnip_config.logger.info("Creating #{resource.class} with name #{resource.name}")
    response = post("/#{resource.uri}", resource.to_xml)
  end

  def addUid(collection, uid)
    @gnip_config.logger.info("Adding uid #{uid.name} to collection #{collection.name}")
    response = post("/collections/#{collection.name}/uids", uid.to_xml)
  end

  def update(resource)
    @gnip_config.logger.info("Updating #{resource.class} with name #{resource.name}")
    response = put("/#{resource.uri}/#{resource.name}.xml", resource.to_xml)
  end

  def remove(resource)
    @gnip_config.logger.info("Removing #{resource.class} with name #{resource.name}")
    response = delete("/#{resource.uri}/#{resource.name}.xml")
  end

  def removeUid(collection, uid)
    @gnip_config.logger.info("Removing uid #{uid.name} from collection #{collection.name}")
    response = delete("/collections/#{collection.name}/uids?uid=#{CGI.escape(uid.name)}&publisher.name=#{CGI.escape(uid.publisher_name)}")
  end


  private

  def self.publishers_from_xml(publishers_xml)
    return [] if publishers_xml.nil?
    publishers_list = XmlSimple.xml_in(publishers_xml)
    return (publishers_list.empty? ? [] : publishers_list['publisher'].collect { |publisher_hash| Gnip::Publisher.from_hash(publisher_hash)})
  end

  def self.list_to_xml(activity_list)
    activity_list = [] if activity_list.nil?
    return XmlSimple.xml_out(activity_list.collect { |activity| activity.to_hash}, {'RootName' => 'activities', 'AnonymousTag' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end

  def self.list_from_xml(activities_xml)
    return [] if activities_xml.nil?
    activities_list = XmlSimple.xml_in(activities_xml)
    return (activities_list.empty? ? [] : activities_list['activity'].collect { |activity_hash| Gnip::Activity.from_hash(activity_hash)})
  end

end
