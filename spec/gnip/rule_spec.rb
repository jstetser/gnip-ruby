require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Rule do
  before do
    prepare_mock_environment
  end
  
  it "should create rule with correct xml format" do
    rule = Gnip::Rule.new('actor', 'jud')

=begin
  Expected XML
<?xml version="1.0" encoding="UTF-8"?>
<rule type="actor" value="jud" />
=end
    rule.to_xml.should include("<rule")
    rule.to_xml.should include("type=\"actor\"")
    rule.to_xml.should include("value=\"jud\"")  
  end

   it 'should unmarshal from xml correctly' do
    rule_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<rule type="actor" value="jud" />
HEREDOC
    rule = Gnip::Rule.from_xml(rule_xml)
    rule.type.should == 'actor'
    rule.value.should == 'jud'
   end
   
   it "should have a method to check the existence of a rule" do
     filter = Gnip::Filter.new('existing-filter')
     rule = Gnip::Rule.new('actor', 'testActor')
     setup_mock_for_find_rule(filter, rule)
     response = Gnip::Rule.exists?(@mock_publisher, filter, rule)
     response.should == true
   end
   
   it "should have a method to find a rule by publisher, filter, and name" do
     filter = Gnip::Filter.new('existing-filter')
     rule = Gnip::Rule.new('actor', 'testActor')
     setup_mock_for_find_rule(filter, rule)
     response = Gnip::Rule.find(@mock_publisher, filter, rule)
     response.should == rule
   end
end
