dir = File.dirname(__FILE__)

require "rubygems"
require "spec"
require "#{dir}/../lib/gnip.rb"

# This is here to allow spec helpers to work with spec_server
$LOAD_PATH.unshift "#{dir}/../lib"

def prepare_mock_environment
  @gnip_config = Gnip::Config.new("user", "password", "s.gnipcentral.com", false)
  @gnip_connection = Gnip::Connection.new(@gnip_config)
  
  @mock_publisher_name = 'mock_pub'
  @mock_filter_name = 'mock_filter'
  @mock_publisher = Gnip::Publisher.new(@mock_publisher_name, [])
  @mock_filter = Gnip::Filter.new(@mock_filter_name, true, @mock_publisher)

  @server_now = Time.now.utc
  @activities = pub_activities
end

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


def setup_mock_for_publishers_get(expected_publishers, expected_scope = 'my')
  mock_response = successful_response
  mock_response.should_receive(:body).with(no_args).and_return(list_to_xml(expected_publishers, 'publishers'))
  mock_http.should_receive(:get2).with("/#{expected_scope}/publishers.xml", headers).and_return(mock_response)
end

def setup_mock_for_publisher_get(expected_publisher_name, expected_scope = 'my')
  mock_response = successful_response
  mock_response.should_receive(:body).with(no_args).and_return(Gnip::Publisher.new(expected_publisher_name, [], expected_scope).to_xml)
  mock_http.should_receive(:get2).with("/#{expected_scope}/publishers/#{expected_publisher_name}.xml", headers).and_return(mock_response)
end

def setup_mock_for_publisher_update(expected_publisher,  expected_scope = 'my')
    mock_http.should_receive(:put2).with("/#{expected_scope}/publishers/#{expected_publisher.name}/#{expected_publisher.name}.xml", expected_publisher.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_publisher_create(expected_publisher, expected_scope = 'my')
  mock_http.should_receive(:post2).with("/#{expected_scope}/publishers", expected_publisher.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_filter_create(expected_filter, expected_scope = 'my')
  mock_http.should_receive(:post2).with("/#{expected_scope}/publishers/#{@mock_publisher_name}/filters", expected_filter.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_find_rule(filter, rule, expected_scope = 'my')
  mock_response = successful_response
  mock_response.should_receive(:body).with(no_args).and_return(Gnip::Rule.new(rule.type, rule.value).to_xml)
  mock_http.should_receive(:get2).with("/#{expected_scope}/publishers/#{@mock_publisher_name}/filters/#{filter.name}/rules.xml?type=#{rule.type}&value=#{rule.value}", headers).and_return(mock_response)
end

def setup_mock_for_add_rules(filter, rules, expected_scope = 'my')
  mock_http.should_receive(:post2).with("/#{expected_scope}/publishers/#{@mock_publisher_name}/filters/#{filter.name}/rules.xml", filter.rules_xml(rules), headers).and_return(successful_response)
end

def setup_mock_for_add_rule(filter, rule, expected_scope = 'my')
  mock_http.should_receive(:post2).with("/#{expected_scope}/publishers/#{@mock_publisher_name}/filters/#{filter.name}/rules.xml", rule.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_delete_rule(filter, rule, expected_scope = 'my')
  mock_http.should_receive(:delete).with("/#{expected_scope}/publishers/#{@mock_publisher_name}/filters/#{filter.name}/rules?type=#{rule.type}&value=#{rule.value}", headers).and_return(successful_response)
end

def setup_mock_for_filter_update(expected_filter, expected_scope = 'my')
  mock_http.should_receive(:put2).with("/#{expected_scope}/publishers/#{@mock_publisher_name}/filters/#{expected_filter.name}.xml", expected_filter.to_xml, headers).and_return(successful_response)
end

def setup_mock_for_filter_delete(expected_filter, expected_scope = 'my')
  mock_http.should_receive(:delete).with("/#{expected_scope}/publishers/#{@mock_publisher_name}/filters/#{expected_filter.name}.xml", headers).and_return(successful_response)
end

def setup_mock_for_filter_find(expected_filter_name, expected_scope = 'my')
  mock_response = successful_response
  mock_response.should_receive(:body).with(no_args).and_return(Gnip::Filter.new(expected_filter_name).to_xml)
  mock_http.should_receive(:get2).with("/#{expected_scope}/publishers/#{@mock_publisher_name}/filters/#{expected_filter_name}.xml", headers).and_return(mock_response)
end

def setup_mock_for_publishing(activities_xml, expected_scope = 'my')
  mock_http.should_receive(:post2).with("/#{expected_scope}/publishers/#{@mock_publisher_name}/activity.xml", activities_xml, headers).and_return(successful_response)
end

def setup_mock_for_publisher(activities, server_time = nil, expected_scope = 'my')
  prefix_path = "/#{expected_scope}/publishers/#{@mock_publisher_name}"
  setup_mock_for_activity_get(activities, prefix_path, server_time)
end

def setup_mock_notification_for_publisher(activities, server_time = nil, expected_scope = 'my')
  prefix_path = "/#{expected_scope}/publishers/#{@mock_publisher_name}"
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

def setup_mock_for_filter(activities, server_time = nil, expected_scope = 'my')
  prefix_path = "/#{expected_scope}/publishers/#{@mock_publisher_name}/filters/#{@mock_filter_name}"
  setup_mock_for_activity_get(activities, prefix_path, server_time)
end

def setup_mock_notification_for_filter(activities, server_time = nil, expected_scope = 'my')
  prefix_path = "/#{expected_scope}/publishers/#{@mock_publisher_name}/filters/#{@mock_filter_name}"
  setup_mock_for_notification_get(activities, prefix_path, server_time)
end

def pub_activities_at(time)
  str = <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity>
      <actor>joe</actor>
      <url>qwerty890</url>
      <action>added_friend</action>
      <at>#{time.xmlschema}</at>
    </activity>
    <activity>
      <actor>jane</actor>
      <url>def456</url>
      <action>added_application</action>
      <at>#{time.xmlschema}</at>
    </activity>
</activities>
  HEREDOC
  str
end

def pub_activities
  str = <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity>
      <actor>joe</actor>
      <url>qwerty890</url>
      <action>added_friend</action>
      <at>2007-05-23T00:53:11+01:00</at>
    </activity>
    <activity>
      <actor>jane</actor>
      <url>def456</url>
      <action>added_application</action>
      <at>2008-05-23T00:52:11+04:00</at>
    </activity>
</activities>
  HEREDOC
  str
end

def special_pub_activities(now)    
  str = <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity>
      <actor>joe</actor>
      <url>qwerty890</url>
      <action>added_friend</action>
      <at>#{now.xmlschema}</at>
    </activity>
    <activity>
      <actor>jane</actor>
      <url>def456</url>
      <action>added_application</action>
      <at>#{now.xmlschema}</at>
    </activity>
</activities>
  HEREDOC
  str
end



def list_to_xml(list, root_name)
  list = [] if list.nil?
  return XmlSimple.xml_out(list.collect { |item| item.to_hash}, {'RootName' => root_name, 'AnonymousTag' => nil, 'XmlDeclaration' => Gnip.header_xml})
end
    
def assert_equals(expected_activities_xml, actual_activities )
  document = REXML::Document.new(expected_activities_xml)

  actual_activities.each_with_index do |activity, index|
    activity_element = document.elements["activities/*[#{(index + 1).to_s}]"]
    activity_element.elements["at"].text.should ==  activity.at
    activity_element.elements["action"].text.should == activity.action
    activity_element.elements["actor"].text.should == activity.actor
  end
end