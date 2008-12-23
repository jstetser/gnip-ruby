class Gnip::Filter < Gnip::Base

    attr_accessor :post_url
    attr_reader :rules, :name, :full_data, :publisher

    def initialize(name, full_data = true, publisher = nil)
        @name = name
        @full_data = full_data
        @rules = []
        @publisher = publisher
    end
    
    def self.find(publisher, filter_name)
      logger.info("Getting filter #{filter_name}")
      find_path = "/publishers/#{publisher.name}/filters/#{filter_name}.xml"
      response, data = self.new(filter_name).get(find_path)
      filter = nil
      if (response.code == '200')
          filter = Gnip::Filter.from_xml(data)
      end
      return [response, filter]
    end
    
    def self.create(name, full_data = true, publisher = nil)
      filter = new(name, full_data, publisher)
      logger.info("Creating #{filter.class} with name #{filter.name}")
      return filter.post("#{publisher.prefix}/#{filter.uri}", filter.to_xml)
    end
    
    def update
      logger.info("Creating #{self.class} with name #{self.name}")
      return put("/#{self.publisher.uri}/#{self.publisher.name}/#{self.uri}/#{self.name}.xml", self.to_xml)
    end
    
    def destroy
      logger.info("Removing #{self.class} with name #{self.name}")
      return delete("/#{self.publisher.uri}/#{self.publisher.name}/#{self.uri}/#{self.name}.xml")
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
    
    # def rules
    #   logger.info("Getting list of rules for filter #{self.name}")
    #   return @rules unless nil
    #   res, data = get("/#{publisher.uri}/#{publisher.name}/filters/#{filter.name}/rules")
    #   @rules = rules_from_xml(data)
    # end
    
    def self.add_rule(publisher, filter, rule)
        logger.info("Adding rule #{rule.value} to filter #{filter.name}")
        return post("/#{publisher.uri}/#{publisher.name}/filters/#{filter.name}/rules.xml", rule.to_xml)
    end

    def self.remove_rule(publisher, filter, rule)
        logger.info("Removing rule #{rule.value} from filter #{filter.name}")
        return delete("/#{publisher.uri}/#{publisher.name}/filters/#{filter.name}/rules?type=#{CGI.escape(rule.type)}&value=#{CGI.escape(rule.value)}") if rule
    end

    def to_xml()
        return XmlSimple.xml_out(self.to_hash, {'RootName' => nil, 'XmlDeclaration' => Gnip.header_xml})
    end

    def to_hash()
        result = {}
        result['name'] = @name
        result['fullData'] = @full_data
        result['postUrl'] = [@post_url]  if @post_url
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
        filter.post_url = hash['postUrl'].first if hash['postUrl']
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

    def self.value_to_boolean(value)
        if value == true || value == false
            value
        else
            %w(true t 1).include?(value.to_s.downcase)
        end
    end

end
