require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Filter do
  before do
    prepare_mock_environment
  end
  
  it 'should know the URI of its activity stream' do
    Gnip::Filter.new('url-safe-name').activity_stream_uri.should == "filters/url-safe-name/activity"
  end 

  it 'should be able to figure the URI of any particular activity bucket' do
    Gnip::Filter.new('url-safe-name').activity_bucket_uri_for(Time.parse('2008-07-11T12:34Z')).should ==
      "filters/url-safe-name/activity/200807111234.xml"
  end 
 
  it "should create filter with correct xml format" do
    filter = Gnip::Filter.new('url-safe-name')
    filter.add_rule("actor", "joe")
    filter.add_rule("actor", "jack")

=begin
  Expected XML:
  <?xml version="1.0" encoding="UTF-8"?>
  <filter name="url-safe-name" fullData="true">
    <rule value="joe" type="actor" />
    <rule value="jack" type="actor" />
  </filter>
=end
    filter.to_xml.should include("<filter")
    filter.to_xml.should include("name=\"url-safe-name\"")
    filter.to_xml.should include("fullData=\"true\"")
    filter.to_xml.should include("<rule ")
    filter.to_xml.should include("value=\"joe\"")
    filter.to_xml.should include("type=\"actor\"")
    filter.to_xml.should include("value=\"jack\"")
    filter.to_xml.should include("type=\"actor\"")
    filter.to_xml.should include("</filter>")
  end

  it "should create filter with correct xml format with POST URL" do
    filter = Gnip::Filter.new('url-safe-name')
    filter.post_url = "http://example.com"
    filter.add_rule("actor", "joe")
    filter.add_rule("actor", "jack")

=begin
  Expected XML:
  <?xml version="1.0" encoding="UTF-8"?>
  <filter name="url-safe-name" fullData="true">
    <postUrl>http://example.com</postUrl>
    <rule value="joe" type="actor" />
    <rule value="jack" type="actor" />
  </filter>
=end
    filter.to_xml.should include("<filter")
    filter.to_xml.should include("name=\"url-safe-name\"")
    filter.to_xml.should include("fullData=\"true\"")
    filter.to_xml.should include("<postUrl>http://example.com</postUrl>")
    filter.to_xml.should include("value=\"joe\"")
    filter.to_xml.should include("type=\"actor\"")
    filter.to_xml.should include("value=\"jack\"")
    filter.to_xml.should include("type=\"actor\"")
    filter.to_xml.should include("</filter>")
  end

   it 'should unmarshall from xml correctly' do
    filter_xml = <<HEREDOC
  <?xml version="1.0" encoding="UTF-8"?>
  <filter name="url-safe-name" fullData="true">
    <rule value="joe" type="actor" />
    <rule value="jack" type="actor" />
  </filter>
HEREDOC

    filter = Gnip::Filter.from_xml(filter_xml)
    filter.name.should == "url-safe-name"
    filter.rules.size.should == 2
    filter.rules[0].value.should == 'joe'
    filter.rules[0].type.should == 'actor'
    filter.rules[1].value.should == 'jack'
    filter.rules[1].type.should == 'actor'
    filter.post_url.should be_nil
   end

  it 'should unmarshall from xml correctly without rules' do
     filter_xml =  <<HEREDOC
  <?xml version="1.0" encoding="UTF-8"?>
  <filter name="url-safe-name" fullData="true">
  </filter>
HEREDOC

    filter = Gnip::Filter.from_xml(filter_xml)
    filter.name.should == "url-safe-name"
    filter.full_data.should == true
    filter.rules.size.should == 0
    filter.post_url.should be_nil
  end

  it 'should unmarshall from xml correctly with POST URL' do
    filter_xml =  <<HEREDOC
  <?xml version="1.0" encoding="UTF-8"?>
  <filter name="url-safe-name" fullData="false">
    <postUrl>http://example.com</postUrl>
    <rule type="actor" value="joe" />
    <rule type="actor" value="jack" />
  </filter>
HEREDOC

    filter = Gnip::Filter.from_xml(filter_xml)
    filter.name.should == "url-safe-name"
    filter.full_data.should == false
    filter.rules.size.should == 2
    filter.rules[0].value.should == 'joe'
    filter.rules[0].type.should == 'actor'
    filter.post_url.should == "http://example.com"
  end

  it "should allow adding and removing actor" do
    filter = Gnip::Filter.new('url-safe-name')
    filter.add_rule('actor','joe')
    filter.add_rule('actor',"jack")
    filter.rules.size.should == 2
    filter.remove_rule('actor',"jack")
    filter.rules.size.should == 1
  end
  
  it 'should have a method for adding a rule' do
    filter = Gnip::Filter.new('existing-filter')
    filter.add_rule('actor', 'testActor')
    filter.rules.size.should == 1
  end
  
  it 'should have a method for removing a rule' do
    filter = Gnip::Filter.new('existing-filter', [], @mock_publisher)
    rule = Gnip::Rule.new('actor', 'testUid')
    filter.add_rule(rule.type, rule.value)
    filter.rules.size.should == 1
    
    filter.remove_rule(rule.type, rule.value)
    filter.rules.size.should == 0
  end
  
  it 'should properly convert an array of rules to XML' do
    filter = Gnip::Filter.new('existing-filter', [], @mock_publisher)
    rules = []
    rules << Gnip::Rule.new('actor', 'joe')
    rules << Gnip::Rule.new('actor', 'jake')

    rule_xml =  <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<rules>
  <rule type="actor" value="joe" />
  <rule type="actor" value="jake" />
</rules>
HEREDOC
    filter.rules_xml(rules).should == rule_xml
  end
  
  it 'should have a method for adding a batch of rules' do
    filter = Gnip::Filter.new('existing-filter', [], @mock_publisher)
    rules = []
    rules << Gnip::Rule.new('actor', 'joe')
    rules << Gnip::Rule.new('actor', 'jake')
    setup_mock_for_add_rules(filter, rules)
    response = filter.add_rules(rules)
    response.code.should == '200'
    filter.rules.size.should == 2
  end   
end
