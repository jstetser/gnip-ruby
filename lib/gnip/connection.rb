require 'pathname'
require Pathname(__FILE__).dirname + '../ext/time'

class Gnip::Connection < Gnip::Base
  
  def initialize(config)
    @gnip_config = config
    
    Gnip.register_connection(self)
  end

  def server_time
    result = head("/")
    Time.httpdate(result['Date']).gmtime
  end

  # Logger for this connection.
  def logger 
    @gnip_config.logger
  end

  # Config object for this connection.
  def config
    @gnip_config
  end
  

  #Publish a activity xml document to gnip for a give publisher
  #You must be the owner of the publisher to publish
  #activities_xml is the xml stream of gnip activities
  def publish_xml(publisher, activity_xml)
    logger.info("Publishing activities for #{publisher.name}")
    publisher_path = "/publishers/#{publisher.name}/activity"
    post(publisher_path, activity_xml)
  end

  #Publish a activity xml document to gnip for a give publisher
  #You must be the owner of the publisher to publish
  #activity_list is an array of activity objects
  def publish(publisher, activity_list)
    logger.info("Publishing activities for #{publisher.name}")
    publisher_path = "/publishers/#{publisher.name}/activity"
    post(publisher_path, Gnip::Activity.list_to_xml(activity_list))
  end

  # Gets the current activities
  # Resource is a publisher or collection resource
  # Time is the time object. If nil, then the server returns the current bucket
  def activities_stream_xml(resource, time = nil)
    timestamp = time ? time.to_gnip_bucket_id : 'current'
    logger.info("Timestamp for #{time} is #{timestamp}")
    logger.info("Getting activities xml for #{resource.name} at #{timestamp}")
    get("/#{resource.uri}/#{resource.name}/activity/#{timestamp}.xml")
  end

  # Gets the current activities
  # Resource is a publisher or collection resource
  # Time is the time object. If nil, then the server returns the current bucket
  def activities_stream(resource, time = nil)
    timestamp = time ? time.to_gnip_bucket_id : 'current'
    logger.info("Timestamp for #{time} is #{timestamp}")
    logger.info("Getting activities for #{resource.name} at #{timestamp}")
    response, activities_xml = get("/#{resource.uri}/#{resource.name}/activity/#{timestamp}.xml")
    activities = []
    activities = Gnip::Connection.list_from_xml(activities_xml) if response.code == '200'
    [response, activities]
  end

  def get_collection(collection_name)
    logger.info("Getting collection #{collection_name}")
    find_path = "/collections/#{collection_name}.xml"
    response, data = get(find_path)
    collection = nil
    if (response.code == '200')
      collection = Gnip::Collection.from_xml(data)
    end
    return [response, collection]
  end

  def get_publisher(publisher_name)
    logger.info("Getting publisher #{publisher_name}")
    get_path = "/publishers/#{publisher_name}.xml"
    response, data = get(get_path)
    publisher = nil
    if (response.code == '200')
      publisher = Gnip::Publisher.from_xml(data)
    end
    return [response, publisher]
  end

  def get_publishers()
    logger.info('Getting publisher list')
    get_path = '/publishers.xml'
    response, data = get(get_path)
    publishers = []
    if (response.code == '200')
      publishers = Gnip::Connection.publishers_from_xml(data)
    end
    return [response, publishers]
  end

  def create(resource)
    logger.info("Creating #{resource.class} with name #{resource.name}")
    response = post("/#{resource.uri}", resource.to_xml)
  end

  def addUid(collection, uid)
    logger.info("Adding uid #{uid.name} to collection #{collection.name}")
    response = post("/collections/#{collection.name}/uids", uid.to_xml)
  end

  def update(resource)
    logger.info("Updating #{resource.class} with name #{resource.name}")
    response = put("/#{resource.uri}/#{resource.name}.xml", resource.to_xml)
  end

  def remove(resource)
    logger.info("Removing #{resource.class} with name #{resource.name}")
    response = delete("/#{resource.uri}/#{resource.name}.xml")
  end

  def removeUid(collection, uid)
    logger.info("Removing uid #{uid.name} from collection #{collection.name}")
    response = delete("/collections/#{collection.name}/uids?uid=#{CGI.escape(uid.name)}&publisher.name=#{CGI.escape(uid.publisher_name)}")
  end

  def head(path)
    logger.debug('Doing HEAD')
    http.get(path,headers)
  end

  def get(path)
    logger.debug('Doing GET')
    response = http.get2(path, headers)
    if (response.code == '200')
      if (response['Content-Encoding'] == 'gzip')
        logger.debug("Uncompressing the GET response")
        data = uncompress(response.body)
      else
        data = response.body
      end
    end
    logger.debug("GET result: #{data}")
    [response, data]
  end

  def post(path, data)
    logger.debug("POSTing data: #{data}")
    http.post2(path, compress(data), headers)
  end

  def put(path, data)
    logger.debug("PUTing data: #{data}")
    http.put2(path, compress(data), headers)
  end

  def delete(path)
    logger.debug("Doing DELETE : #{path}")
    http.delete(path, headers)
  end

  private

  def http
    hostname, port = @gnip_config.base_url.split(':')
    port ||= 443

    returning Net::HTTP.new(hostname, port) do |http|
      http.read_timeout=5
      if port == 443
        http.use_ssl = true
      end
    end
  end

  def headers
    header_hash = {}
    header_hash['Authorization'] = 'Basic ' + Base64::encode64("#{@gnip_config.user}:#{@gnip_config.password}")
    header_hash['Content-Type'] = 'application/xml'
    if @gnip_config.use_gzip
      header_hash['Content-Encoding'] = 'gzip'
      header_hash['Accept-Encoding'] = 'gzip'
    end
    logger.debug("Gnip Connection Headers: #{header_hash}")
    header_hash
  end

  def compress(data)
    logger.debug("Gzipping data for request")
    if @gnip_config.use_gzip
      result = ''
      gzip_writer = Zlib::GzipWriter.new(StringIO.new(result))
      gzip_writer.write(data)
      gzip_writer.close
    else
      result = data
    end
    result
  end

  def uncompress(data)
    Zlib::GzipReader.new(StringIO.new(data)).read
  end

  def self.publishers_from_xml(publishers_xml)
    return [] if publishers_xml.nil?
    publishers_list = XmlSimple.xml_in(publishers_xml)
    return (publishers_list.empty? ? [] : publishers_list['publisher'].collect { |publisher_hash| Gnip::Publisher.from_hash(publisher_hash)})
  end

  def self.list_from_xml(activities_xml)
    return [] if activities_xml.nil?
    activities_list = XmlSimple.xml_in(activities_xml)
    return (activities_list.empty? ? [] : activities_list['activity'].collect { |activity_hash| Gnip::Activity.from_hash(activity_hash)})
  end

end
