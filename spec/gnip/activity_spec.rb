require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Activity do
  describe '.list_to_xml(activities)' do
    it 'should marshal a list of activities to xml' do 
      activity_list = []
      activity_list << Gnip::Activity.new("joe", "added_friend", Time.parse('2007-05-23T00:53:11Z'), "qwerty890")
      activity_list << Gnip::Activity.new("jane", "added_application", Time.parse('2008-08-23T00:53:11Z'), "def456")
      
      Gnip::Activity.list_to_xml(activity_list).should == <<XML
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity guid="qwerty890" type="added_friend" uid="joe" at="2007-05-23T00:53:11Z" />
    <activity guid="def456" type="added_application" uid="jane" at="2008-08-23T00:53:11Z" />
</activities>
XML
    end

    it 'should marshal an empty list of activities to xml' do 
      activity_list = []
      
      Gnip::Activity.list_to_xml(activity_list).should == <<XML
<?xml version="1.0" encoding="UTF-8"?>
<activities>
</activities>
XML
    end    
  end 
  
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
    activity.guid.should be_nil
    activity.publisher.should be_nil
  end

  it "should unmarshal from xml correctly with guid" do
    now = Time.now
    activity_xml =  "<activity at=\"#{now.xmlschema}\" uid=\"bob\" type=\"type\" guid=\"guid\" />"
    activity = Gnip::Activity.from_xml(activity_xml)
    activity.at.should == now.xmlschema
    activity.uid.should == 'bob'
    activity.type.should == 'type'
    activity.guid.should == 'guid'
    activity.publisher.should be_nil
   end

   it "should unmarshal from xml correctly with publisher" do
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
