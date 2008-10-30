require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Rule do
  it "should create rule with correct xml format" do
    rule = Gnip::Rule.new('actor', 'jud')

    rule.to_xml.should == <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<rule type="actor" value="jud" />
HEREDOC
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
end
