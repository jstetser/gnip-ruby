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
    
    #Publish a activity xml document to gnip for a give publisher
    #You must be the owner of the publisher to publish
    #activities_xml is the xml stream of gnip activities
    def publish_xml(publisher, activity_xml)
      publisher.publish_xml(activity_xml)
    end

    #Publish a activity xml document to gnip for a give publisher
    #You must be the owner of the publisher to publish
    #activity_list is an array of activity objects
    def publish(publisher, activity_list)
      publisher.publish(activity_list)
    end

    # Gets the current activities for a publisher
    # Time is the time object. If nil, then the server returns the current bucket
    def publisher_activities_stream_xml(publisher, time = nil)
      publisher.activities_xml(time)
    end

    # Gets the current activities for a publisher
    # Time is the time object. If nil, then the server returns the current bucket
    def publisher_activities_stream(publisher, time = nil)
      publisher.activities(time)
    end

    # Gets the current activities for a filter
    # Time is the time object. If nil, then the server returns the current bucket
    def filter_activities_stream_xml(publisher, filter, time = nil)
      publisher.activities_xml(time, filter)
    end

    # Gets the current activities for a filter
    # Time is the time object. If nil, then the server returns the current bucket
    def filter_activities_stream(publisher, filter, time = nil)
      publisher.activities(time, filter)
    end

    # Gets the current notifications for a publisher
    # Time is the time object. If nil, then the server returns the current bucket
    def publisher_notifications_stream_xml(publisher, time = nil)
      publisher.notifications_xml(time)
    end

    # Gets the current notifications for a publisher
    # Time is the time object. If nil, then the server returns the current bucket
    def publisher_notifications_stream(publisher, time = nil)
      publisher.notifications(time)
    end

    # Gets the current notifications for a filter
    # Time is the time object. If nil, then the server returns the current bucket
    def filter_notifications_stream_xml(publisher, filter, time = nil)
      publisher.notifications_xml(time, filter)
    end

    # Gets the current notifications for a filter
    # Time is the time object. If nil, then the server returns the current bucket
    def filter_notifications_stream(publisher, filter, time = nil)
      publisher.notifications(time, filter)
    end

    def get_publisher(publisher_name, scope = 'my')
      Gnip::Publisher.find(publisher_name, scope)
    end

    def get_publishers()
        logger.info('Getting publisher list')
        get_path = '/my/publishers.xml'
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
      publisher.update(publisher)
    end
    
    def get_filter(publisher, filter_name)
      Gnip::Filter.find(publisher, filter_name)
    end

    def create_filter(publisher, filter)
      Gnip::Filter.create(filter.name, filter.full_data, publisher)
    end

    def update_filter(publisher, filter)
      filter.update(publisher)
    end

    def remove_filter(publisher, filter)
      filter.destroy(publisher)
    end

    def add_rule(publisher, filter, rule)
      filter.add_rules(rule, publisher)
    end

    def remove_rule(publisher, filter, rule)
      filter.remove_rule!(rule.type, rule.value, publisher)
    end

    def head(path)
        logger.debug('Doing HEAD')
        return http.get(path, headers)
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
        return [response, data]
    end

    def post(path, data)
        logger.debug("POSTing data: #{data}")
        return http.post2(path, compress(data), headers)
    end

    def put(path, data)
        logger.debug("PUTing data: #{data}")
        return http.put2(path, compress(data), headers)
    end

    def delete(path)
        logger.debug("Doing DELETE : #{path}")
        return http.delete(path, headers)
    end

    private

    def self.publishers_from_xml(publishers_xml)
        return [] if publishers_xml.nil?
        publishers_list = XmlSimple.xml_in(publishers_xml)
        return (publishers_list.empty? ? [] : publishers_list['publisher'].collect { |publisher_hash| Gnip::Publisher.from_hash(publisher_hash)})
    end
end
