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

    describe "Notifictaion Streams For Subscriber" do
        it "should get activities per publisher for a given time" do
            setup_mock_notification_for_publisher( @activities, @server_now)
            response, activities = @gnip_connection.publisher_notifications_stream(@mock_publisher, @server_now)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end

        it "should get current activites  per publisher " do
            setup_mock_notification_for_publisher(@activities)
            response, activities = @gnip_connection.publisher_notifications_stream(@mock_publisher)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end

        it "should get current activites  for a publicly scoped publisher " do
            setup_mock_notification_for_publisher(@activities, nil, "public")
            @mock_publisher.scope="public"
            response, activities = @gnip_connection.publisher_notifications_stream(@mock_publisher)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end


        it "should get current activites  for a gnip scoped publisher " do
            setup_mock_notification_for_publisher(@activities, nil, "gnip")
            @mock_publisher.scope="gnip"
            response, activities = @gnip_connection.publisher_notifications_stream(@mock_publisher)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end

        it "should get activities per filter for a given time" do
            setup_mock_notification_for_filter(@activities, @server_now)
            response, activities = @gnip_connection.filter_notifications_stream(@mock_publisher, @mock_filter, @server_now)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end

        it "should get current activites per filter" do
            setup_mock_notification_for_filter(@activities)
            response, activities = @gnip_connection.filter_notifications_stream(@mock_publisher, @mock_filter)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end
    end

    describe "ActivityStream" do

        describe "For Subscriber" do
            it "should get activities per publisher for a given time" do
                setup_mock_for_publisher( @activities, @server_now)
                response, activities = @gnip_connection.publisher_activities_stream(@mock_publisher, @server_now)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end

            it "should get current activites  per publisher " do
                setup_mock_for_publisher(@activities)
                response, activities = @gnip_connection.publisher_activities_stream(@mock_publisher)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end

            it "should get current activites  for a publicly scoped publisher " do
                setup_mock_for_publisher(@activities, nil, "public")
                @mock_publisher.scope="public"
                response, activities = @gnip_connection.publisher_activities_stream(@mock_publisher)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end


            it "should get current activites  for a gnip scoped publisher " do
                setup_mock_for_publisher(@activities, nil, "gnip")
                @mock_publisher.scope="gnip"
                response, activities = @gnip_connection.publisher_activities_stream(@mock_publisher)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end

            it "should get activities per filter for a given time" do
                setup_mock_for_filter(@activities, @server_now)
                response, activities = @gnip_connection.filter_activities_stream(@mock_publisher, @mock_filter, @server_now)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end

            it "should get current activites per filter" do
                setup_mock_for_filter(@activities)
                response, activities = @gnip_connection.filter_activities_stream(@mock_publisher, @mock_filter)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end
        end

        describe "For Publisher" do

            it "should post activities as xml successfully" do
                setup_mock_for_publishing(@activities)
                response = @gnip_connection.publish_xml(@mock_publisher, @activities)
                response.code.should == "200"
            end

            it "should post activities as list successfully" do
                now = Time.now
                activity_list = []
                activity_list << Gnip::Activity.new("joe", "added_friend", now, "qwerty890")
                activity_list << Gnip::Activity.new("jane", "added_application", now, "def456")
                setup_mock_for_publishing(pub_activities_at(now))
                response = @gnip_connection.publish(@mock_publisher, activity_list)
                response.code.should == "200"
            end
        end

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


    describe "Filter" do

        ['my', 'public', 'gnip'].each do |scope|

            it "should create a new filter for given filter xml" do
                filter = Gnip::Filter.new('new-filter')
                setup_mock_for_filter_create(filter, scope)
                @mock_publisher.scope=scope
                response = @gnip_connection.create_filter(@mock_publisher, filter)
                response.code.should == "200"
            end

            it "should find a filter for given name" do
                filter_name = 'some-existing-filter'
                setup_mock_for_filter_find(filter_name, scope)
                @mock_publisher.scope=scope
                response, filter = @gnip_connection.get_filter(@mock_publisher, filter_name)
                response.code.should == "200"
                filter.name.should == 'some-existing-filter'
            end

            it "should update a filter for given filter" do
                filter = Gnip::Filter.new('existing-filter')
                setup_mock_for_filter_update(filter, scope)
                @mock_publisher.scope=scope
                response = @gnip_connection.update_filter(@mock_publisher, filter)
                response.code.should == "200"
            end

            it 'should add a rule to the given filter' do
                filter = Gnip::Filter.new('existing-filter')
                rule = Gnip::Rule.new('actor', 'testActor')
                setup_mock_for_add_rule(filter, rule, scope)
                @mock_publisher.scope=scope
                response = @gnip_connection.add_rule(@mock_publisher, filter, rule)
                response.code.should == "200"
            end

            it 'should remove a rule from the given filter' do
                filter = Gnip::Filter.new('existing-filter')
                rule = Gnip::Rule.new('actor', 'testUid')
                setup_mock_for_delete_rule(filter, rule, scope)
                @mock_publisher.scope=scope
                response = @gnip_connection.remove_rule(@mock_publisher, filter, rule)
                response.code.should == "200"
            end

            it "should delete a filter for given filter" do
                filter = Gnip::Filter.new('existing-filter')
                setup_mock_for_filter_delete(filter, scope)
                @mock_publisher.scope=scope
                response = @gnip_connection.remove_filter(@mock_publisher, filter)
                response.code.should == "200"
            end

        end
    end

    describe "Publisher" do

        it "should create a new publisher" do
            publisher = Gnip::Publisher.new('new-publisher')
            setup_mock_for_publisher_create(publisher)
            publisher.scope = 'my'
            response = @gnip_connection.create_publisher(publisher)
            response.should == publisher
        end

        ['my', 'public', 'gnip'].each do |scope|
            it "should return a  publisher for given publisher name and scope" do
                publisher_name = 'existing-publsher'
                setup_mock_for_publisher_get(publisher_name, scope)
                publisher = @gnip_connection.get_publisher(publisher_name, scope)
                publisher.name.should == publisher_name
                publisher.scope.should == scope
            end
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
