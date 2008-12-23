dir = File.dirname(__FILE__)

require "rubygems"
require "spec"
require "#{dir}/../lib/gnip.rb"

# This is here to allow spec helpers to work with spec_server
$LOAD_PATH.unshift "#{dir}/../lib"

def expected_gnip_headers_for_last_poll_time(last_poll_time_server)
  expected_headers = {'AUTHORIZATION' => 'Basic ' + Base64::encode64("#{DEMO_USERNAME}:#{DEMO_PASSWORD}")}
  expected_headers.merge!({'IF_MODIFIED_SINCE' => last_poll_time_server.httpdate}) unless last_poll_time_server.nil?
  expected_headers
end

def mock_gnip_head
  mock_gnip_head = mock('current time request')
  mock_head = mock('head result')
  mock_head.should_receive(:[]).with('Date').and_return(@server_now.httpdate)
  mock_gnip_head.should_receive(:head2).with('/', expected_gnip_headers_for_last_poll_time(nil)).and_return(mock_head)
  mock_gnip_head
end

def mock_http
    a_mock = mock('http_mock')
    Net::HTTP.should_receive(:new).with(@gnip_config.base_url, 443).and_return(a_mock)
    a_mock.should_receive(:use_ssl=).with(true)
    a_mock.should_receive(:read_timeout=).with(5)
    a_mock
end

def headers
    @gnip_connection.send(:headers)
end

def successful_response
    response = mock('response')
    response.should_receive(:code).with(no_args).any_number_of_times.and_return("200")
    response.should_receive(:[]).with('Content-Encoding').any_number_of_times.and_return('')
    response
end

def setup_mock_for_publishers_get(expected_publishers)
    mock_response = successful_response
    mock_response.should_receive(:body).with(no_args).and_return(list_to_xml(expected_publishers, 'publishers'))
    mock_http.should_receive(:get2).with("/publishers.xml", headers).and_return(mock_response)
end

def setup_mock_for_publisher_get(expected_publisher_name)
    mock_response = successful_response
    mock_response.should_receive(:body).with(no_args).and_return(Gnip::Publisher.new(expected_publisher_name).to_xml)
    mock_http.should_receive(:get2).with("/publishers/#{expected_publisher_name}.xml", headers).and_return(mock_response)
end

def setup_mock_for_publisher_create(expected_publisher)
    mock_http.should_receive(:post2).with("/publishers", expected_publisher.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_publisher_update(expected_publisher)
    mock_http.should_receive(:put2).with("/publishers/#{expected_publisher.name}/#{expected_publisher.name}.xml", expected_publisher.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_filter_create(expected_filter)
    mock_http.should_receive(:post2).with("/publishers/#{@mock_publisher_name}/filters", expected_filter.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_add_rule(filter, rule)
    mock_http.should_receive(:post2).with("/publishers/#{@mock_publisher_name}/filters/#{filter.name}/rules.xml", rule.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_delete_rule(filter, rule)
    mock_http.should_receive(:delete).with("/publishers/#{@mock_publisher_name}/filters/#{filter.name}/rules?type=#{rule.type}&value=#{rule.value}", headers).and_return(successful_response)
end

def setup_mock_for_filter_update(expected_filter)
    mock_http.should_receive(:put2).with("/publishers/#{@mock_publisher_name}/filters/#{expected_filter.name}.xml", expected_filter.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_filter_delete(expected_filter)
    mock_http.should_receive(:delete).with("/publishers/#{@mock_publisher_name}/filters/#{expected_filter.name}.xml", headers).and_return(successful_response)
end

def setup_mock_for_filter_find(expected_filter_name)
    mock_response = successful_response
    mock_response.should_receive(:body).with(no_args).and_return(Gnip::Filter.new(expected_filter_name).to_xml)
    mock_http.should_receive(:get2).with("/publishers/#{@mock_publisher_name}/filters/#{expected_filter_name}.xml", headers).and_return(mock_response)
end

def setup_mock_for_publishing(activities_xml)
    mock_http.should_receive(:post2).with("/publishers/#{@mock_publisher_name}/activity.xml", activities_xml, headers).and_return(successful_response)
end

def setup_mock_for_publisher(activities, server_time = nil)
    prefix_path = "/publishers/#{@mock_publisher_name}"
    setup_mock_for_activity_get(activities, prefix_path, server_time)
end

def setup_mock_notification_for_publisher(activities, server_time = nil)
    prefix_path = "/publishers/#{@mock_publisher_name}"
    setup_mock_for_notification_get(activities, prefix_path, server_time)
end

def setup_mock_for_activity_get(activities, prefix_path, server_time = nil)
    headers = @gnip_connection.send(:headers)
    path =
            if (server_time)
                "#{prefix_path}/activity/#{server_time.to_gnip_bucket_id}.xml"
            else
                "#{prefix_path}/activity/current.xml"
            end
    mock_response = successful_response
    mock_response.should_receive(:body).and_return(activities)
    mock_http.should_receive(:get2).with(path, headers).and_return(mock_response)
end

def setup_mock_for_notification_get(activities, prefix_path, server_time = nil)
    headers = @gnip_connection.send(:headers)
    path =
            if (server_time)
                "#{prefix_path}/notification/#{server_time.to_gnip_bucket_id}.xml"
            else
                "#{prefix_path}/notification/current.xml"
            end
    mock_response = successful_response
    mock_response.should_receive(:body).and_return(activities)
    mock_http.should_receive(:get2).with(path, headers).and_return(mock_response)
end

def setup_mock_for_filter(activities, server_time = nil)
    prefix_path = "/publishers/#{@mock_publisher_name}/filters/#{@mock_filter_name}"
    setup_mock_for_activity_get(activities, prefix_path, server_time)
end

def setup_mock_notification_for_filter(activities, server_time = nil)
    prefix_path = "/publishers/#{@mock_publisher_name}/filters/#{@mock_filter_name}"
    setup_mock_for_notification_get(activities, prefix_path, server_time)
end

def pub_activities_at(time)
    str = <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity actor="joe" url="qwerty890" action="added_friend" at="#{time.xmlschema}" />
    <activity actor="jane" url="def456" action="added_application" at="#{time.xmlschema}" />
</activities>
    HEREDOC
    str
end

def pub_activities
    str = <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity actor="joe" url="qwerty890" action="added_friend" at="2007-05-23T00:53:11+01:00" />
    <activity actor="jane" url="def456" action="added_application" at="2008-05-23T00:52:11+04:00" />
</activities>
    HEREDOC
    str
end

def list_to_xml(list, root_name)
    list = [] if list.nil?
    return XmlSimple.xml_out(list.collect { |item| item.to_hash}, {'RootName' => root_name, 'AnonymousTag' => nil, 'XmlDeclaration' => Gnip.header_xml})
end
