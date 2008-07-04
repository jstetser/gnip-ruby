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

