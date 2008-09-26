class Gnip::Activity

    attr_reader :actor, :at, :url, :action, :to, :regarding, :source, :tags, :payload

    def initialize(actor, action, at = Time.now, url = nil, to = nil, regarding = nil, source = nil, tags = nil, payload = nil)
        @actor = actor
        @action = action
        if (at.class == Time)
            @at = at.xmlschema
        else
            @at = at unless Time.xmlschema(at).nil?
        end
        @url = url
        @to = to
        @regarding = regarding
        @source = source
        @tags = tags
        @payload = payload
    end

    def to_xml()
        XmlSimple.xml_out(self.to_hash, {'RootName' => ''})
    end

    def to_hash()
        result = {}
        result['at'] = @at
        result['actor'] = @actor
        result['action'] = @action
        result['url'] = @url if @url
        result['to'] = @to if @to
        result['regarding'] = @regarding if @regarding
        result['source'] = @source if @source
        result['tags'] = @tags if @tags
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
        Gnip::Activity.new(hash['actor'], hash['action'], hash['at'], hash['url'], hash['to'], hash['regarding'], hash['source'], hash['tags'], payload)
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

end
