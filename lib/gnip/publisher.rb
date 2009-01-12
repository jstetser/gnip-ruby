class Gnip::Publisher < Gnip::Base
  attr_reader :name, :filters
  attr_accessor :supported_rule_types
  attr_accessor :scope

  def initialize(name, suppported_rule_types = [], scope = 'my')
    @name = name
    @scope = scope
    @supported_rule_types = suppported_rule_types
    @filters = {}
  end
  
  ## API 
  
  def self.find(publisher_name, scope = 'my')
    Gnip::Base.logger.info("Getting publisher #{publisher_name}")
    get_path = "/#{scope}/publishers/#{publisher_name}.xml"
    response, data = Gnip::Base.connection.get(get_path)
    publisher = nil
    if (response.code == '200')
      publisher = Gnip::Publisher.from_xml(data)
      publisher.scope = scope
      return publisher
    else 
      Gnip::Base.logger.info("Received error response #{response.code}")
      nil
    end
  end
  
  def self.create(name, suppported_rule_types = [], scope = 'my')
    publisher = new(name, suppported_rule_types, scope)
    publisher.create
  end
  
  def create
    logger.info("Creating #{self.class} with name #{self.name}")
    return self if post("/#{@scope}/publishers", self.to_xml)
  end
  
  def update
    logger.info("Updating #{self.class} with name #{self.name}")
    return put("#{self.uri}/#{self.name}.xml", self.to_xml)
  end
  
  # Gets the current activities for a publisher
  # Time is the time object. If nil, then the server returns the current bucket
  def activities_xml(time = nil, filter = nil)
    timestamp = time ? time.to_gnip_bucket_id : 'current'
    if filter
      _name, _endpoint = filter.name, "#{self.uri}/#{filter.path}/activity/#{timestamp}.xml"
    else
      _name, _endpoint = self.name, "#{self.uri}/activity/#{timestamp}.xml"
    end
    log_action(_name, time, timestamp)
    response, activities_xml = fetch(_endpoint)
  end
      
  # Gets the current activities for a publisher
  # Time is the time object. If nil, then the server returns the current bucket
  # If a filter is given, we get the current activities for that filter
  def activities(time = nil, filter = nil)
    parse_xml(*activities_xml(time, filter))
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
  def notifications_xml(time = nil, filter = nil)
    timestamp = time ? time.to_gnip_bucket_id : 'current'
    if filter
      _name, _endpoint = filter.name, "#{self.uri}/#{filter.path}/notification/#{timestamp}.xml"
    else
      _name, _endpoint = self.name, "#{self.uri}/notification/#{timestamp}.xml"
    end
    log_action(_name, time, timestamp)
    response, notifications_xml = fetch(_endpoint)
  end
  
  # Gets the current activities for a publisher
  # Time is the time object. If nil, then the server returns the current bucket
  # If a filter is given, we get the current activities for that filter
  def notifications(time = nil, filter = nil)
    parse_xml(*notifications_xml(time, filter))
  end
  
  alias_method :get_notifications, :notifications
  
  # Gets notifications for a filter. 
  # Takes an optional time object
  def get_filtered_notifications(filter, time)
    notifications(time, filter)
  end
  
  # Publish a activity xml document to gnip for a give publisher
  # You must be the owner of the publisher to publish
  # activities_xml is the xml stream of gnip activities
  def publish_xml(activity_xml)
    logger.info("Publishing activities for #{self.name}")
    publisher_path = "#{self.uri}/activity.xml"
    post(publisher_path, activity_xml)
  end
  
  # Publish a activity xml document to gnip for a give publisher
  # You must be the owner of the publisher to publish
  # activity_list is an array of activity objects
  def publish(activity_list)
    publish_xml(Gnip::Activity.list_to_xml(activity_list))
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
    "/#{@scope}/publishers/#{@name}"
  end

  def prefix
    "/#{self.uri}/#{self.name}"
  end

  def to_xml()
    return XmlSimple.xml_out(self.to_hash, {'RootName' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end

  def to_hash()
    result = {}
    result['name'] = self.name
    result['supportedRuleTypes'] = @supported_rule_types.collect { |type| type.to_hash}
    { 'publisher' => result }
  end

  def ==(object)
    object.instance_of?(self.class) && @name == object.name
  end
  alias :eql? :==

  def self.from_hash(hash, scope = 'my')
      found_rule_types = []
      rule_types = hash['supportedRuleTypes']
        if rule_types
            rule_types.each do |rule_type_hash|                
                found_rule_types << Gnip::RuleType.from_hash(rule_type_hash['type'].first)
            end
        end
    return Gnip::Publisher.new(hash['name'], found_rule_types, scope)
  end

  def self.from_xml(document, scope = 'my')
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash, scope)
  end

  private


  def path
    "/my/publishers/#{name}/activity"
  end
  
  def log_action(name, time, timestamp)
    logger.info("Timestamp for #{time} is #{timestamp}")
    logger.info("Getting activities for #{name} at #{timestamp}")
  end
  
  def fetch(endpoint)
    response, activities_xml = get(endpoint)
  end
  
  def parse_xml(response, activities_xml)
    activities = []
    activities = Gnip::Activity.list_from_xml(activities_xml) if response.code == '200'
    return [response, activities]
  end
end
