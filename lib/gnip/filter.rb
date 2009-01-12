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
      find_path = "/#{publisher.scope}/publishers/#{publisher.name}/filters/#{filter_name}.xml"
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
      return filter.post("#{publisher.uri}/#{filter.uri}", filter.to_xml)
    end
    
    def update(publisher = self.publisher)
      logger.info("Creating #{self.class} with name #{self.name}")
      return put("#{publisher.uri}/#{self.uri}/#{self.name}.xml", self.to_xml)
    end
    
    def destroy(publisher = self.publisher)
      logger.info("Removing #{self.class} with name #{self.name}")
      return delete("#{publisher.uri}/#{self.uri}/#{self.name}.xml")
    end

    def uri
        'filters'
    end
    
    def path
      "#{self.uri}/#{self.name}"
    end
    
    def prefix(publisher = self.publisher)
      "#{publisher.uri}/#{self.uri}/#{self.name}"
    end
    
    def has_rule?(type, value)
      @rules.include?(Gnip::Rule.new(type, value))
    end
    
    def add_rules(ruleset = [], publisher = self.publisher)
      unless ruleset.is_a?(Array)
        logger.info("Adding Rule (#{ruleset.type}:#{ruleset.value}) to filter named #{self.name} for publisher #{publisher.name}")
        response = post(ruleset.uri(publisher, self, :extension => :xml), ruleset.to_xml)
        ruleset = [ruleset]
      else
        logger.info("Bulk adding rules to filter named #{self.name} for publisher #{publisher.name}")
        response = post(ruleset.first.uri(publisher, self, :extension => :xml), rules_xml(ruleset))
      end
      if response.code == '200'
        ruleset.each { |r| add_rule(r.type, r.value) }
      end
      return response
    end

    def add_rule(type, value)
        @rules << Gnip::Rule.new(type, value) unless has_rule?(type, value)
    end
    
    def add_rule!(type, value)
      add_rule(type, value) && update
    end
    
    def remove_rule(type, value)
        @rules.delete(Gnip::Rule.new(type, value)) if has_rule?(type, value)
    end
    
    def remove_rule!(type, value, publisher = self.publisher)
      remove_rule(type, value)
      rule = Gnip::Rule.new(type, value)
      return delete(rule.uri(publisher, self, :specific => true))
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
    
    def rules_xml(ruleset)
      return XmlSimple.xml_out(ruleset.collect { |rule| rule.to_hash }, {'AnonymousTag' => 'rule', 'RootName' => 'rules', 'XmlDeclaration' => Gnip.header_xml})
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
