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
  
  describe "add_filter method" do
    before do
      @publisher = Gnip::Publisher.new('url-safe-name')
    end
    
    it "should create a new filter and add it to the publisher's list of filters" do
      @publisher.filters.size.should be(0)
      @publisher.add_filter("test_filter", true)
      @publisher.filters.size.should_not be(0)
      
      @publisher.filters["test_filter"].should == Gnip::Filter.new("test_filter", true, @publisher)
    end
  end
  
  describe "delete_filter method" do
    before do
      @publisher = Gnip::Publisher.new('url-safe-name')
    end
    
    it "should remove the filter named in the list" do
      @publisher.add_filter("test_filter", true)
      @publisher.filters.size.should be(1)
      
      @publisher.delete_filter("test_filter")   
      @publisher.filters.size.should be(0)
      @publisher.filters["test_filter"].should be(nil)
    end
  end
        
  describe "filters" do
    before do
      @publisher = Gnip::Publisher.new('url-safe-name')
    end
    
    it "should return an empty hash if there are no filters" do
      @publisher.filters.should be_is_a(Hash)
      @publisher.filters.should == {}
    end
  
    it "should return a hash of filters if any are defined" do
      @publisher.add_filter("test_filter", true)
      @publisher.filters.should be_is_a(Hash)
      @publisher.filters.should_not be_empty
    end
    
    it "should return the appropriate filter when using filters[name] syntax" do
      @publisher.add_filter("test_filter", true)
      @publisher.filters["test_filter"].should == Gnip::Filter.new("test_filter", true, @publisher)
    end
  end
  
  describe "A test publisher" do
    before do 
      @gnip_config = Gnip::Config.new("user", "password", "s.gnipcentral.com", false)
      @gnip_connection = Gnip::Connection.new(@gnip_config)
      
      @mock_publisher_name = 'mock_pub'
      @mock_filter_name = 'mock_filter'
      @mock_publisher = Gnip::Publisher.new(@mock_publisher_name, [], @gnip_connection)
      @mock_filter = Gnip::Filter.new(@mock_filter_name, true, @mock_publisher)

      @server_now = Time.now.utc
      @activities = pub_activities
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

    # describe "publish method" do
    # end
  end
end
