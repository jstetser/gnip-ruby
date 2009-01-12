require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Publisher do
  
  it 'should unmarshal from xml correctly' do
    publisher_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <publisher name="url-safe-name">
    <supportedRuleTypes>
      <type>actor</type>
    </supportedRuleTypes>
  </publisher>
HEREDOC
    publisher = Gnip::Publisher.from_xml(publisher_xml)
    publisher.name.should == "url-safe-name"      
    publisher.supported_rule_types[0].value.should == 'actor'
  end

  it 'should unmarshal from xml list correctly' do
    publishers_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <publishers>
    <publisher name="url-safe-name1">
      <supportedRuleTypes>
        <type>actor</type>
      </supportedRuleTypes>
    </publisher>
    <publisher name="url-safe-name2">
      <supportedRuleTypes>
        <type>source</type>
      </supportedRuleTypes>
    </publisher>
  </publishers>
HEREDOC
    publishers_list = XmlSimple.xml_in(publishers_xml)
    publishers =  publishers_list['publisher'].collect { |publisher_hash| Gnip::Publisher.from_hash(publisher_hash)}
    publishers[0].name.should == "url-safe-name1"     
    publishers[0].supported_rule_types[0].value.should == 'actor'
    publishers[1].name.should == "url-safe-name2"
    publishers[1].supported_rule_types[0].value.should == 'source'
   end

  it 'should marshal to xml correctly' do
    publisher = Gnip::Publisher.new('url-safe-name')
    publisher.supported_rule_types << Gnip::RuleType.new('actor')
    publisher.to_xml.should ==  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <publisher name="url-safe-name">
    <supportedRuleTypes>
      <type>actor</type>
    </supportedRuleTypes>
  </publisher>
HEREDOC
  end

  it 'should be equal if names are equal' do
    publisher1 = Gnip::Publisher.new('url-safe-name')
    publisher2 = Gnip::Publisher.new('url-safe-name')
    publisher1.should == publisher2
  end
  
  # describe "add_filter method" do
  #   before do
  #     @gnip_config = Gnip::Config.new("user", "password", "s.gnipcentral.com", false)
  #     @gnip_connection = Gnip::Connection.new(@gnip_config)
  #     @publisher = Gnip::Publisher.new('url-safe-name', [], @gnip_connection)
  #   end
  #   
  #   it "should create a new filter and add it to the publisher's list of filters" do
  #     @publisher.filters.size.should be(0)
  #     @publisher.add_filter("test_filter", true)
  #     @publisher.filters.size.should_not be(0)
  #     
  #     @publisher.filters["test_filter"].should == Gnip::Filter.new("test_filter", true, @publisher)
  #   end
  # end
  # 
  # describe "delete_filter method" do
  #   before do
  #     @publisher = Gnip::Publisher.new('url-safe-name')
  #   end
  #   
  #   it "should remove the filter named in the list" do
  #     @publisher.add_filter("test_filter", true)
  #     @publisher.filters.size.should be(1)
  #     
  #     @publisher.delete_filter("test_filter")   
  #     @publisher.filters.size.should be(0)
  #     @publisher.filters["test_filter"].should be(nil)
  #   end
  # end
  #       
  # describe "filters" do
  #   before do
  #     @publisher = Gnip::Publisher.new('url-safe-name')
  #   end
  #   
  #   it "should return an empty hash if there are no filters" do
  #     @publisher.filters.should be_is_a(Hash)
  #     @publisher.filters.should == {}
  #   end
  # 
  #   it "should return a hash of filters if any are defined" do
  #     @publisher.add_filter("test_filter", true)
  #     @publisher.filters.should be_is_a(Hash)
  #     @publisher.filters.should_not be_empty
  #   end
  #   
  #   it "should return the appropriate filter when using filters[name] syntax" do
  #     @publisher.add_filter("test_filter", true)
  #     @publisher.filters["test_filter"].should == Gnip::Filter.new("test_filter", true, @publisher)
  #   end
  # end

  
  describe "A test publisher" do
    before do 
      prepare_mock_environment
    end
    
    describe "class" do
      it "should have a find method that returns a publisher for given publisher name" do
        publisher_name = 'existing-publisher'
        setup_mock_for_publisher_get(publisher_name)
        publisher = Gnip::Publisher.find(publisher_name)
        publisher.name.should == publisher_name
      end
      
      it "should have a create method" do
        publisher = Gnip::Publisher.new('new-publisher', [])
        setup_mock_for_publisher_create(publisher)
        response = Gnip::Publisher.create('new-publisher', [])
        response.should == publisher
      end
    end
    
    describe "instance" do
    
      it "should have a create method" do
        publisher = Gnip::Publisher.new('new-publisher', [])
        setup_mock_for_publisher_create(publisher)
        response = publisher.create
        response.should == publisher
      end
      
      it "should have an update method" do
        publisher = Gnip::Publisher.new('new-publisher', [])
        setup_mock_for_publisher_update(publisher)
        response = publisher.update
        response.code.should == "200"
      end
  
      describe "activities method" do
    
        it "should get activities per publisher for a given time" do
          setup_mock_for_publisher(@activities, @server_now)
          response, activities = @mock_publisher.activities(@server_now)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
        
        it "should get current activities per publisher " do
          setup_mock_for_publisher(@activities)
          response, activities = @mock_publisher.activities
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
    
        it "should be aliased as get_activities" do
          setup_mock_for_publisher(@activities, @server_now)
          response, activities = @mock_publisher.get_activities(@server_now)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
    
        it "should get activities per filter for a given time if a filter is given" do
          setup_mock_for_filter(@activities, @server_now)
          response, activities = @mock_publisher.activities(@server_now, @mock_filter)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
      
        it "should get current activities per filter if a filter is given w/o a time" do
          setup_mock_for_filter(@activities)
          response, activities = @mock_publisher.activities(nil, @mock_filter)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
    
        it "should be accessible as get_filtered_activities" do
          setup_mock_for_filter(@activities, @server_now)
          response, activities = @mock_publisher.get_filtered_activities(@mock_filter, @server_now)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
      end
  
      describe "notifications method" do
    
        it "should get notifications per publisher for a given time" do
          setup_mock_notification_for_publisher( @activities, @server_now)
          response, activities = @mock_publisher.notifications(@server_now)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
      
        it "should get current notifications per publisher " do
          setup_mock_notification_for_publisher( @activities)
          response, activities = @mock_publisher.notifications
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
      
        it "should be aliased as get_notifications" do
          setup_mock_notification_for_publisher( @activities, @server_now)
          response, activities = @mock_publisher.get_notifications(@server_now)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
      
        it "should get notifications per filter for a given time if a filter is given" do
          setup_mock_notification_for_filter(@activities, @server_now)
          response, activities = @mock_publisher.notifications(@server_now, @mock_filter)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
      
        it "should get current notifications per filter if a filter is given w/o a time" do
          setup_mock_notification_for_filter(@activities)
          response, activities = @mock_publisher.notifications(nil, @mock_filter)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
      
        it "should be accessible as get_filtered_notifications" do
          setup_mock_notification_for_filter(@activities, @server_now)
          response, activities = @mock_publisher.get_filtered_notifications(@mock_filter, @server_now)
          response.code.should == '200'
          Gnip::Activity.list_to_xml(activities).should == @activities
        end
      end

      describe "publish method" do
        it "should post activities as list successfully" do
          now = Time.now
          activity_list = []
          activity_list << Gnip::Activity.new("joe", "added_friend", now, "qwerty890")
          activity_list << Gnip::Activity.new("jane", "added_application", now, "def456")
          setup_mock_for_publishing(pub_activities_at(now))
          response = @mock_publisher.publish(activity_list)
          response.code.should == "200"
        end
      end
    
      describe "with filters" do
        it "should create a new filter for given filter xml" do
            filter = Gnip::Filter.new('new-filter', true, @mock_publisher)
            setup_mock_for_filter_create(filter)
            response = @mock_publisher.add_filter('new-filter', true)
            response.code.should == "200"
        end

        it "should find a filter for given name" do
          filter_name = 'existing-filter'
          filter = Gnip::Filter.new(filter_name, true, @mock_publisher)
          @mock_publisher.filters[filter_name] = filter            
          setup_mock_for_filter_find(filter_name)
            response, filter = @mock_publisher.get_filter(filter_name)
            response.code.should == "200"
            filter.name.should == filter_name
        end

        it "should update a filter for given filter" do
          filter = Gnip::Filter.new('existing-filter', true, @mock_publisher)
          
          setup_mock_for_filter_update(filter)
          response = filter.update
          response.code.should == "200"
        end

        it "should delete a filter for given filter" do
          filter = Gnip::Filter.new('existing-filter', true, @mock_publisher)
          @mock_publisher.filters['existing-filter'] = filter
          setup_mock_for_filter_delete(filter)
          response = @mock_publisher.delete_filter('existing-filter')
          response.code.should == "200"
        end
      end
    end
  end
end
