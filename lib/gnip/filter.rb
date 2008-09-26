class Gnip::Filter

    attr_accessor :post_url, :jid
    attr_reader :rules, :name, :full_data

    def initialize(name, full_data = true)
        @name = name
        @full_data = full_data
        @rules = []
    end

    def uri
        'filters'
    end

    def add_rule(type, value)
        @rules << Gnip::Rule.new(type, value)
    end

    def remove_rule(type, value)
        @rules.delete(Gnip::Rule.new(type, value))
    end

    def to_xml()
        return XmlSimple.xml_out(self.to_hash, {'RootName' => nil, 'XmlDeclaration' => Gnip.header_xml})
    end

    def to_hash()
        result = {}
        result['name'] = @name
        result['fullData'] = @full_data
        result['postUrl'] = @post_url if @post_url
        result['jid'] = @jid if @jid
        result['rule'] = rules.collect { |rule| rule.to_hash()}
        { 'filter' => result }
    end

    def eql?(object)
        self == object
    end

    def ==(object)
        object.instance_of?(self.class) && @name == object.name
    end

    def full_data=(full_data)
        @full_data = Gnip::Filter.value_to_boolean(full_data)
    end

    def self.from_hash(hash)
        filter = new(hash['name'])
        filter.full_data = value_to_boolean(hash['fullData'])
        filter.post_url = hash['postUrl'] if hash['postUrl']
        filter.jid = hash['jid'] if hash['jid']
        rules = hash['rule']
        if rules
            rules.each do |rule_hash|
                filter.add_a_rule(Gnip::Rule.from_hash(rule_hash))
            end
        end
        return filter
    end

    def self.from_xml(document)
        hash = XmlSimple.xml_in(document)
        return self.from_hash(hash)
    end


    # The URI of this filters activity stream.
    def activity_stream_uri
        "filters/#{name}/activity"
    end

    # The URI to a particular activity bucket of this filters
    # activity stream.
    def activity_bucket_uri_for(at_time)
        "filters/#{name}/activity/#{at_time.to_gnip_bucket_id}.xml"
    end

    def add_a_rule(rule)
        @rules << rule
    end

    private

    # The logger this object should use.
    def logger
        Gnip.logger
    end

    def self.value_to_boolean(value)
        if value == true || value == false
            value
        else
            %w(true t 1).include?(value.to_s.downcase)
        end
    end

end
