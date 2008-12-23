class Gnip::Connection < Gnip::Base

    def initialize(config)
        @gnip_config = config
        Gnip.connection = self
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

    def get_publisher(publisher_name)
      Gnip::Publisher.find(publisher_name, self)
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

    def create_publisher(publisher)
      publisher.create
    end

    def update_publisher(publisher)
      publisher.update
    end

    def add_rule(publisher, filter, rule)
        logger.info("Adding rule #{rule.value} to filter #{filter.name}")
        return post("/#{publisher.uri}/#{publisher.name}/filters/#{filter.name}/rules.xml", rule.to_xml)
    end

    def remove_rule(publisher, filter, rule)
        logger.info("Removing rule #{rule.value} from filter #{filter.name}")
        return delete("/#{publisher.uri}/#{publisher.name}/filters/#{filter.name}/rules?type=#{CGI.escape(rule.type)}&value=#{CGI.escape(rule.value)}") if rule
    end

    private

    def self.publishers_from_xml(publishers_xml)
        return [] if publishers_xml.nil?
        publishers_list = XmlSimple.xml_in(publishers_xml)
        return (publishers_list.empty? ? [] : publishers_list['publisher'].collect { |publisher_hash| Gnip::Publisher.from_hash(publisher_hash)})
    end
end
