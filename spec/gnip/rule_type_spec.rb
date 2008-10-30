require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::RuleType do
  it "should create rule type with correct xml format" do
    rule_type = Gnip::RuleType.new('actor')

    rule_type.to_xml.should == <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <type>actor</type>
HEREDOC
  end


   it 'should unmarshal from xml correctly' do
    rule_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <type>actor</type>
HEREDOC
    rule_type = Gnip::RuleType.from_xml(rule_xml)
    rule_type.value.should == 'actor'
   end
end
