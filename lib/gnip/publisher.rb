class Gnip::Publisher
  attr_reader :name, :filters, :connection
  attr_accessor :supported_rule_types

  def initialize(name, suppported_rule_types = [], connection = nil)
    @name = name
    @supported_rule_types = suppported_rule_types
    @filters = {}
    @connection = connection
  end
  
  ## API 
  
  def self.find(publisher_name, connection)
    connection.logger.info("Getting publisher #{publisher_name}")
    get_path = "/publishers/#{publisher_name}.xml"
    response, data = connection.get(get_path)
    publisher = nil
    if (response.code == '200')
      publisher = Gnip::Publisher.from_xml(data)
    else 
      connection.logger.info("Received error response #{response.code}")
      nil
    end
  end
  
  def self.create(name, suppported_rule_types = [], connection = nil)
    publisher = new(name, suppported_rule_types, connection)
    publisher.create
  end
  
  def create
    self.connection.logger.info("Creating #{self.class} with name #{self.name}")
    return self if connection.post("/#{self.uri}", self.to_xml)
  end
  
  def update
    connection.logger.info("Updating #{self.class} with name #{self.name}")
    return connection.put("/#{self.uri}/#{self.name}/#{self.name}.xml", self.to_xml)
  end
      
  # Gets the current activities for a publisher
  # Time is the time object. If nil, then the server returns the current bucket
  # If a filter is given, we get the current activities for that filter
  def activities(time = nil, filter = nil)
    timestamp = time ? time.to_gnip_bucket_id : 'current'
    if filter
      _name, _endpoint = filter.name, "#{self.prefix}/#{filter.uri}/#{filter.name}/activity/#{timestamp}.xml"
    else
      _name, _endpoint = self.name, "#{self.prefix}/activity/#{timestamp}.xml"
    end
    log_action(_name, time, timestamp)
    fetch_and_parse(_endpoint)
  end
  
  alias_method :get_activities, :activities
  
  # Gets activities for a filter. 
  # Takes an optional time object
  def get_filtered_activities(filter, time)
    activities(time, filter)
  end
  
  # Gets the current activities for a publisher
  # Time is the time object. If nil, then the server returns the current bucket
  # If a filter is given, we get the current activities for that filter
  def notifications(time = nil, filter = nil)
    timestamp = time ? time.to_gnip_bucket_id : 'current'
    if filter
      _name, _endpoint = filter.name, "#{self.prefix}/#{filter.uri}/#{filter.name}/notification/#{timestamp}.xml"
    else
      _name, _endpoint = self.name, "#{self.prefix}/notification/#{timestamp}.xml"
    end
    log_action(_name, time, timestamp)
    fetch_and_parse(_endpoint)
  end
  
  alias_method :get_notifications, :notifications
  
  # Gets notifications for a filter. 
  # Takes an optional time object
  def get_filtered_notifications(filter, time)
    notifications(time, filter)
  end
  
  # Publish a activity xml document to gnip for a give publisher
  # You must be the owner of the publisher to publish
  # activity_list is an array of activity objects
  def publish(activity_list)
    @connection.logger.info("Publishing activities for #{self.name}")
    publisher_path = "/publishers/#{self.name}/activity.xml"
    @connection.post(publisher_path, Gnip::Activity.list_to_xml(activity_list))
  end
  ####
  
  def add_filter(name, full_data = true)
    self.filters[name] = Gnip::Filter.create(name, full_data, self)
  end
  
  def get_filter(name)
    Gnip::Filter.find(self, name)
  end
  
  def delete_filter(filter)
    filter = self.filters.delete(filter) if filter.is_a?(String) 
    return filter.destroy
  end
  
  def uri
    'publishers'
  end

  def prefix
    "/#{self.uri}/#{self.name}"
  end

  def to_xml()
    return XmlSimple.xml_out(self.to_hash, {'RootName' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end

  def to_hash()
    result = {}
    result['name'] = @name
    result['supportedRuleTypes'] = @supported_rule_types.collect { |type| type.to_hash}
    { 'publisher' => result }
  end

  def ==(object)
    object.instance_of?(self.class) && @name == object.name
  end
  alias :eql? :==

  def self.from_hash(hash)       
      found_rule_types = []
      rule_types = hash['supportedRuleTypes']
        if rule_types
            rule_types.each do |rule_type_hash|                
                found_rule_types << Gnip::RuleType.from_hash(rule_type_hash['type'].first)
            end
        end
    return Gnip::Publisher.new(hash['name'], found_rule_types)
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash)
  end

  private


  def path
    "/publishers/#{name}/activity"
  end
  
  def log_action(name, time, timestamp)
    @connection.logger.info("Timestamp for #{time} is #{timestamp}")
    @connection.logger.info("Getting activities for #{name} at #{timestamp}")
  end
  
  def fetch_and_parse(endpoint)
    response, activities_xml = @connection.get(endpoint)
    activities = []
    activities = Gnip::Activity.list_from_xml(activities_xml) if response.code == '200'
    return [response, activities]
  end
end
