require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Activity do
  it "should marshall to xml correctly" do
    now = Time.now
    activity = Gnip::Activity.new('bob','type', now)

    activity_xml =  "  <activity type=\"type\" uid=\"bob\" at=\"#{now.xmlschema}\" />\n"
    activity.to_xml.should == activity_xml
  end

  it "should marshall to xml correctly with guid" do
    now = Time.now
    activity = Gnip::Activity.new('bob','type',now,"guid")

    activity_xml =  "  <activity guid=\"guid\" type=\"type\" uid=\"bob\" at=\"#{now.xmlschema}\" />\n"
    activity.to_xml.should == activity_xml
  end
  
  it "should marshall to xml correctly with publisher" do
    now = Time.now
    activity = Gnip::Activity.new('bob','type',now,'guid','publisher')
    
    activity_xml = "  <activity guid=\"guid\" type=\"type\" uid=\"bob\" publisher.name=\"publisher\" at=\"#{now.xmlschema}\" />\n"
    activity.to_xml.should == activity_xml
  end

  it "should marshall from xml correctly" do
    now = Time.now
    activity_xml =  "<activity at=\"#{now.xmlschema}\" uid=\"bob\" type=\"type\" />"
    activity = Gnip::Activity.from_xml(activity_xml)
    activity.at.should == now.xmlschema
    activity.uid.should == 'bob'
    activity.type.should == 'type'
  end

   it 'should unmarshal from xml correctly with guid' do
    now = Time.now
    activity_xml =  "<activity at=\"#{now.xmlschema}\" uid=\"bob\" type=\"type\" guid=\"guid\" />"
    activity = Gnip::Activity.from_xml(activity_xml)
    activity.at.should == now.xmlschema
    activity.uid.should == 'bob'
    activity.type.should == 'type'
    activity.guid.should == 'guid'
   end

   it 'should unmarshal from xml correctly with publisher' do
    now = Time.now
    activity_xml =  "<activity at=\"#{now.xmlschema}\" uid=\"bob\" type=\"type\" guid=\"guid\" publisher.name=\"publisher\"/>"
    activity = Gnip::Activity.from_xml(activity_xml)
    activity.at.should == now.xmlschema
    activity.uid.should == 'bob'
    activity.type.should == 'type'
    activity.guid.should == 'guid'
    activity.publisher.should == 'publisher'
   end
end
