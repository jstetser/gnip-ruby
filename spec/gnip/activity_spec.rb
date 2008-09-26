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

  describe '.from_xml(activity_xml)' do 
    
    it 'should have the correct activities' do
      activity_xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<activities publisher="test">
    <activity url="qwerty890" action="added_friend" actor="joe" to="jane" regarding="def456" tags="dogs,cats" source="web" at="2007-05-23T00:53:11Z" />
    <activity url="def456" action="added_application" actor="jane" at="2008-08-23T00:53:11Z" />
    <activity action="added_application" actor="jane" at="2008-08-23T00:53:11Z" />
</activities>
XML

      publisher, activities = Gnip::Activity.list_from_xml(activity_xml)
      publisher.name.should == 'test'
      activities.should have(3).items
      activities.should include(Gnip::Activity.new("joe", "added_friend", Time.parse('2007-05-23T00:53:11Z'), "qwerty890"))
      activities.should include(Gnip::Activity.new("jane", "added_application", Time.parse('2008-08-23T00:53:11Z'), "def456"))
    end 

    it 'should handle activities xml without activities' do
      activity_xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<activities>
</activities>
XML

      Gnip::Activity.from_xml(activity_xml).should be_nil
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
    <activity actor="joe" url="qwerty890" action="added_friend" at="2007-05-23T00:53:11Z" />
    <activity actor="jane" url="def456" action="added_application" at="2008-08-23T00:53:11Z" />
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

    activity_xml =  "  <activity actor=\"bob\" action=\"type\" at=\"#{now.xmlschema}\" />\n"
    activity.to_xml.should == activity_xml
  end

  it "should marshall to xml correctly with guid" do
    now = Time.now
    activity = Gnip::Activity.new('bob','action',now,"url")

    activity_xml =  "  <activity actor=\"bob\" url=\"url\" action=\"action\" at=\"#{now.xmlschema}\" />\n"
    activity.to_xml.should == activity_xml
  end
  
  it "should marshall to xml correctly with publisher" do
    now = Time.now
    activity = Gnip::Activity.new('bob','action',now,'url','to')
    
    activity_xml = "  <activity actor=\"bob\" url=\"url\" action=\"action\" to=\"to\" at=\"#{now.xmlschema}\" />\n"
    activity.to_xml.should == activity_xml
  end

  it "should marshall from xml correctly" do
    now = Time.now
    activity_xml =  "<activity at=\"#{now.xmlschema}\" actor=\"bob\" action=\"action\" />"
    activity = Gnip::Activity.from_xml(activity_xml)
    activity.at.should == now.xmlschema
    activity.actor.should == 'bob'
    activity.action.should == 'action'
    activity.url.should be_nil
    activity.to.should be_nil
    activity.regarding.should be_nil
    activity.source.should be_nil
    activity.tags.should be_nil
    activity.payload.should be_nil
  end

  it "should unmarshal from xml correctly with url" do
    now = Time.now
    activity_xml =  "<activity at=\"#{now.xmlschema}\" actor=\"bob\" action=\"action\" url=\"url\" />"
    activity = Gnip::Activity.from_xml(activity_xml)
    activity.at.should == now.xmlschema
    activity.actor.should == 'bob'
    activity.action.should == 'action'
    activity.url.should == 'url'
    activity.to.should be_nil
    activity.regarding.should be_nil
    activity.source.should be_nil
    activity.tags.should be_nil
    activity.payload.should be_nil
   end

   it "should unmarshal from xml correctly with to" do
    now = Time.now
    activity_xml =  "<activity at=\"#{now.xmlschema}\" actor=\"bob\" action=\"action\" url=\"url\" to=\"to\"/>"
    activity = Gnip::Activity.from_xml(activity_xml)
    activity.at.should == now.xmlschema
    activity.actor.should == 'bob'
    activity.action.should == 'action'
    activity.url.should == 'url'
    activity.to.should == 'to'
    activity.regarding.should be_nil
    activity.tags.should be_nil
    activity.source.should be_nil
    activity.payload.should be_nil
   end

 it "should unmarshal from xml correctly with all fields" do
    now = Time.now
    activity_xml =  '<activity url="qwerty890" action="added_friend" actor="joe" to="jane" regarding="def456" tags="dogs,cats" source="web" at="2007-05-23T00:53:11Z" />'
    activity = Gnip::Activity.from_xml(activity_xml)
    activity.at.should == '2007-05-23T00:53:11Z'
    activity.actor.should == 'joe'
    activity.action.should == 'added_friend'
    activity.url.should == 'qwerty890'
    activity.to.should == 'jane'
    activity.regarding == 'def456'
    activity.source == 'web'
    activity.tags == "dogs,cats"
    activity.payload.should be_nil
 end

 it "should unmarshal from xml correctly with all fields and payload" do
    now = Time.now
    activity_xml =  '<activity url="qwerty890" action="added_friend" actor="joe" to="jane" regarding="def456" tags="dogs,cats" source="web" at="2007-05-23T00:53:11Z" ><payload><body>body</body></payload></activity>'
    activity = Gnip::Activity.from_xml(activity_xml)
    activity.at.should == '2007-05-23T00:53:11Z'
    activity.actor.should == 'joe'
    activity.action.should == 'added_friend'
    activity.url.should == 'qwerty890'
    activity.to.should == 'jane'
    activity.regarding == 'def456'
    activity.source == 'web'
    activity.tags == "dogs,cats"
    activity.payload.body == 'body'
    activity.payload.raw.should be_nil
  end

end
