require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Connection do


    before do
        @mock_publisher_name = 'mock_pub'
        @mock_filter_name = 'mock_filter'
        @mock_publisher = Gnip::Publisher.new(@mock_publisher_name)
        @mock_filter = Gnip::Filter.new(@mock_filter_name)

        @server_now = Time.now.utc
        @activities = pub_activities
        @gnip_config = Gnip::Config.new("user", "password", "s.gnipcentral.com", false)
        @gnip_connection = Gnip::Connection.new(@gnip_config)
    end

    describe "Request Header" do
        it "should include an agent string header" do
            header = @gnip_connection.send(:headers)
            header['User-Agent'].should == "Gnip-Client-Ruby/2.0.6"
        end

        it "should include authorization header" do
            header = @gnip_connection.send(:headers)
            header['Authorization'].should ==  'Basic ' + Base64::encode64("#{@gnip_config.user}:#{@gnip_config.password}")
        end

        it 'should include content type header' do
            header = @gnip_connection.send(:headers)
            header['Content-Type'].should == 'application/xml'
        end

        it "should include gzip header if configured for gzip" do
            gnip_config = Gnip::Config.new("user", "password", "s.gnipcentral.com", true)
            gnip_connection = Gnip::Connection.new(gnip_config)
            header = gnip_connection.send(:headers)
            header['Content-Encoding'].should == 'gzip'
            header['Accept-Encoding'].should == 'gzip'
        end

        it "should include gzip header if configured for gzip" do
            header = @gnip_connection.send(:headers)
            header['Content-Encoding'].should == nil
            header['Accept-Encoding'].should == nil
        end
    end

    describe "ActivityStream" do

        it 'should marshall to a list correctly' do
            now = Time.now
            activity_xml =  pub_activities_at(now)
            activity_list = Gnip::Activity.list_from_xml(activity_xml)
            activity = activity_list[0]
            activity.at.should == now.xmlschema
            activity.actor.should == 'joe'
            activity.action.should == 'added_friend'
            activity.url.should == 'qwerty890'
            activity = activity_list[1]
            activity.at.should == now.xmlschema
            activity.actor.should == 'jane'
            activity.action.should == 'added_application'
            activity.url.should == 'def456'
        end

    end

    describe "Publishers" do
        it 'should list existing publishers' do
            setup_mock_for_publishers_get([@mock_publisher])
            response, publishers = @gnip_connection.get_publishers
            response.code.should == "200"
            publishers.include?(@mock_publisher).should be_true
        end
    end

end
