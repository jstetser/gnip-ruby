class Gnip::Activity

  attr_reader :actor, :at, :url, :action, :tos, :regardingURL, :source, :tags, :payload

  def initialize(actor, action, at = Time.now, url = nil, tos = [], regardingURL = nil, source = nil, tags = [], payload = nil)
    @actor = actor
    @action = action
    if (at.class == Time)
      @at = at.xmlschema
    else
      @at = at unless Time.xmlschema(at).nil?
    end
    @url = url
    @tos = tos
    @regardingURL = regardingURL
    @source = source
    @tags = tags
    @payload = payload
  end

  def to_xml()
    the_hash = self.to_hash
    XmlSimple.xml_out(the_hash, {'RootName' => ''})
  end

  def to_hash()
    result = {}
    result['at'] = [@at]
    result['action'] = [@action]
    result['actor'] = [@actor] if @actor
    result['url'] = [@url] if @url
    result['to'] = @tos if @tos
    result['regardingURL'] = [@regardingURL] if @regardingURL
    result['source'] = [@source] if @source
    result['tag'] = @tags if @tags
    result['payload'] = @payload.to_hash if @payload

    {'activity' => result }
  end

  def ==(another)
    another.instance_of?(self.class) && another.at == at && another.url == url && another.action == action && another.actor == actor
  end

  alias eql? ==

  def self.from_hash(hash)
    return if hash.nil? || hash.empty?    
    payload = Gnip::Payload.from_hash(hash['payload'].first) if hash['payload']
    Gnip::Activity.new(first(hash['actor']), first(hash['action']), first(hash['at']),
             first(hash['url']), hash['to'], first(hash['regardingURL']), first(hash['source']), hash['tag'], payload)
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    self.from_hash(hash)
  end

  def self.list_to_xml(activity_list)
    activity_list = [] if activity_list.nil?
    return XmlSimple.xml_out(activity_list.collect { |activity| activity.to_hash}, {'RootName' => 'activities', 'AnonymousTag' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end

  def self.list_from_xml(activities_xml)
    return [] if activities_xml.nil?
    activities_list = XmlSimple.xml_in(activities_xml)
    publisher_name = activities_list['publisher']
    publisher = Gnip::Publisher.new(publisher_name) if publisher_name
    activities = (activities_list.empty? ? [] : activities_list['activity'].collect { |activity_hash| Gnip::Activity.from_hash(activity_hash)})
    if (publisher.nil?)
      return activities
    else
      return publisher, activities
    end
  end

  class Gnip::Activity::Builder

    def initialize(action, at = Time.now)
      @action = action
      @at = at
      @tags = []
      @tos = []
    end

    def actor(actor)
      @actor = actor
      self
    end

    def url(url)
      @url = url
      self
    end

    def tos(tos = [])
      @tos = tos
      self
    end

    def to(to)
      @tos.push(to)
      self
    end

    def tags(tags = [])
      @tags = tags
      self
    end

    def tag(tag)
      @tags.push(tag)
      self
    end

    def regardingURL(regardingURL)
      @regardingURL = regardingURL
      self
    end

    def source(source)
      @source = source
      self
    end

    def payload(payload)
      @payload = payload
      self
    end

    def build
      Gnip::Activity.new(@actor, @action, @at, @url, @tos, @regardingURL, @source, @tags, @payload)
    end

  end

  private

  def self.first(array)
    array[0] unless array.nil?
  end

end
