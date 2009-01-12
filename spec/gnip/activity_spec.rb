require "rexml/document"
require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Activity do
  it 'should known when another activity is equal to itself' do
    a = Gnip::Activity::Builder.new("added_friend", Time.parse('2007-05-23T00:53:11Z')).actor("joe").build()
    b = Gnip::Activity::Builder.new("added_friend", Time.parse('2007-05-23T00:53:11Z')).actor("joe").build()

    (a == b).should be_true
    a.eql?(b).should be_true
  end

  it 'should know when another activity is not equal to itself' do
    a = Gnip::Activity::Builder.new("added_friend", Time.parse('2007-05-23T00:53:11Z')).actor("joe").build()
    b = Gnip::Activity::Builder.new("added_friend", Time.parse('2008-05-23T00:53:11Z')).actor("joe").build()

    (a == b).should be_false
    a.eql?(b).should be_false
  end

  describe '.from_xml(activity_xml)' do

    it 'should have the correct activities' do
      activity_xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<activities publisher="test">
    <activity>
        <at>2007-05-23T00:53:11Z</at>
        <action>added_friend</action>
        <actor>joe</actor>        
    </activity>
    <activity>
        <at>2008-08-23T00:53:11Z</at>
        <action>added_application</action>
        <actor>jane</actor>
    </activity>
    <activity>
        <at>2008-08-23T00:53:11Z</at>
        <action>added_application</action>
        <actor>joe</actor>
    </activity>
</activities>
XML

      publisher, activities = Gnip::Activity.list_from_xml(activity_xml)
      publisher.name.should == 'test'
      activities.should have(3).items
      activities.should include(Gnip::Activity::Builder.new("added_friend", Time.parse('2007-05-23T00:53:11Z')).actor("joe").build())
      activities.should include(Gnip::Activity::Builder.new("added_application", Time.parse('2008-08-23T00:53:11Z')).actor("jane").build())
      activities.should include(Gnip::Activity::Builder.new("added_application", Time.parse('2008-08-23T00:53:11Z')).actor("joe").build())

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
      activity_list << Gnip::Activity::Builder.new("added_friend", Time.parse('2007-05-23T00:53:11Z')).actor("joe").build()
      activity_list << Gnip::Activity::Builder.new("added_application", Time.parse('2008-05-23T00:53:11Z')).actor("jane").build()

      document = REXML::Document.new Gnip::Activity.list_to_xml(activity_list)

      activity_list.each_with_index do |activity, index|
        activity_element = document.elements["activities/*[#{(index + 1).to_s}]"]
        activity_element.elements["at"].text.should ==  activity.at
        activity_element.elements["action"].text.should == activity.action
        activity_element.elements["actor"].text.should == activity.actor
      end
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
    activity = Gnip::Activity::Builder.new('upload', now).actor('bob').build()

    document = REXML::Document.new activity.to_xml
    document.elements["activity/at"].text.should == activity.at
    document.elements["activity/action"].text.should == activity.action
    document.elements["activity/actor"].text.should == activity.actor
  end

  it "should marshall to xml correctly with to" do
    now = Time.now
    activity = Gnip::Activity::Builder.new('upload', now).actor('bob').to('to').build()

    document = REXML::Document.new activity.to_xml
    document.elements["activity/at"].text.should == activity.at
    document.elements["activity/action"].text.should == activity.action
    document.elements["activity/actor"].text.should == activity.actor
    document.elements.each("activity/to") { |element| element.text.should == activity.tos[0] }
  end

  it "should marshall to xml correctly with payload" do
    now = Time.now
    payload = Gnip::Payload::Builder.new("raw").body("body").build()
    activity = Gnip::Activity::Builder.new('upload', now).actor('bob').to('to').payload(payload).build()

    document = REXML::Document.new activity.to_xml
    document.elements["activity/at"].text.should == activity.at
    document.elements["activity/action"].text.should == activity.action
    document.elements["activity/actor"].text.should == activity.actor
    document.elements.each("activity/to") { |element| element.text.should == activity.tos[0] }
    document.elements["activity/payload/body"].text.should == activity.payload.body
    document.elements["activity/payload/raw"].text.should == activity.payload.raw_value

  end

  it "should unmarshall from xml correctly" do
    now = Time.now
    activity_xml = "<activity><at>#{now.xmlschema}</at><actor>bob</actor><action>upload</action></activity>"

    activity = Gnip::Activity.from_xml(activity_xml)

    activity.at.should == now.xmlschema
    activity.actor.should == 'bob'
    activity.action.should == 'upload'
    activity.payload.should be_nil
  end

  it "should unmarshal from xml correctly with to" do
    now = Time.now
    activity_xml = "<activity><at>#{now.xmlschema}</at><actor>bob</actor><action>upload</action><to>to</to></activity>"

    activity = Gnip::Activity.from_xml(activity_xml)

    activity.at.should == now.xmlschema
    activity.action.should == 'upload'
    activity.actor.should == 'bob'
    activity.tos[0].should == 'to'
    activity.payload.should be_nil
  end

  it "should unmarshal from xml correctly with all fields" do
    now = Time.now
    activity_xml = '<activity><at>2007-05-23T00:53:11Z</at><action>added_friend</action><actor>joe</actor><to>jane</to><regardingURL>def456</regardingURL><tag>dogs</tag><tag>cats</tag><source>web</source></activity>'

    activity = Gnip::Activity.from_xml(activity_xml)

    activity.at.should == '2007-05-23T00:53:11Z'
    activity.action.should == 'added_friend'
    activity.actor.should == 'joe'
    activity.tos[0].should == 'jane'
    activity.regardingURL.should == 'def456'
    activity.source.should == 'web'
    activity.tags[0].should == 'dogs'
    activity.tags[1].should == 'cats'
    activity.payload.should be_nil

  end

end
