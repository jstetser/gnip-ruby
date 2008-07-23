require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Activity do
  it 'should known when another activity is equal to itself' do
    a = Gnip::Activity.new("joe", "added_friend", Time.parse('2007-05-23T00:53:11Z'), "qwerty890")
    b = Gnip::Activity.new("joe", "added_friend", Time.parse('2007-05-23T00:53:11Z'), "qwerty890")
    
    (a == b).should be_true
    a.eql?(b).should be_true
  end 

  it 'should know when another activity is not equal to itself' do
    a = Gnip::Activity.new("joe", "added_friend", Time.parse('2007-05-23T00:53:11Z'), "qwerty890")
    b = Gnip::Activity.new("joe", "added_friend", Time.parse('2007-05-23T00:53:11Z'), "some other guid")

    (a == b).should be_false
    a.eql?(b).should be_false    
  end 

  describe '.unmarshal_activity_xml(activity_xml)' do 
    it 'should return an enumerable containing Gnip:Activities' do
      activity_xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity guid="qwerty890" type="added_friend" uid="joe" at="2007-05-23T00:53:11Z" />
    <activity guid="def456" type="added_application" uid="jane" at="2008-08-23T00:53:11Z" />
</activities>
XML
      
      Gnip::Activity.unmarshal_activity_xml(activity_xml).should be_kind_of(Enumerable)
      Gnip::Activity.unmarshal_activity_xml(activity_xml).each {|thing| thing.should be_kind_of(Gnip::Activity) }
    end
    
    it 'should have the correct activities' do
      activity_xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity guid="qwerty890" type="added_friend" uid="joe" at="2007-05-23T00:53:11Z" />
    <activity guid="def456" type="added_application" uid="jane" at="2008-08-23T00:53:11Z" />
</activities>
XML

      Gnip::Activity.unmarshal_activity_xml(activity_xml).should have(2).items
      Gnip::Activity.unmarshal_activity_xml(activity_xml).should include(Gnip::Activity.new("joe", "added_friend", Time.parse('2007-05-23T00:53:11Z'), "qwerty890"))
      Gnip::Activity.unmarshal_activity_xml(activity_xml).should include(Gnip::Activity.new("jane", "added_application", Time.parse('2008-08-23T00:53:11Z'), "def456"))
    end 

    it 'should handle activities xml with not activities' do
      activity_xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<activities>
</activities>
XML

      Gnip::Activity.unmarshal_activity_xml(activity_xml).should be_empty
    end
  end
  
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
