require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Collection do
  it 'should know the URI of its activity stream' do
    Gnip::Collection.new('url-safe-name').activity_stream_uri.should == "/collections/url-safe-name/activity"
  end 

  it 'should be able to figure the URI of any particular activity bucket' do
    Gnip::Collection.new('url-safe-name').activity_bucket_uri_for(Time.parse('2008-07-11T12:34Z')).should == 
      "/collections/url-safe-name/activity/200807111230.xml"
  end 
  
  describe '#activities()' do
    before do
      @empty_activities_set_xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<activities>
</activities>
XML
   
      @ok_response = mock('Ok HTTP Response', :code => '200')

      Gnip.connect("test@gnip.invalid", "hello")
      Gnip.connection.stub!(:get).and_return([@ok_response, @empty_activities_set_xml])
    end

    it 'should get the xml from the canonical Gnip connection' do
      Gnip.connection.should_receive(:get).and_return([@ok_response, @empty_activities_set_xml])

      Gnip::Collection.new("foo").activities
    end 

    it 'should unmarshal the activities XML into an Enumerable' do
      Gnip::Collection.new("foo").activities.should be_kind_of(Enumerable)
    end 

    it 'should unmarshal the activities XML into an array of activities' do
      Gnip.connection.stub!(:get).and_return([@ok_response, <<ACTIVITIES_XML])
<activities>
  <activity at="2008-07-23T10:00:00Z" guid="hello-42" uid="me" type="post"/>
</activities>
ACTIVITIES_XML

      Gnip::Collection.new("foo").activities.should have(1).items
      Gnip::Collection.new("foo").activities.first.guid.should == 'hello-42'
    end 
  end

 
  it "should create collection with correct xml format" do
    collection = Gnip::Collection.new('url-safe-name')
    collection.add_uid("joe", "twitter")
    collection.add_uid("jack", "digg")

    collection.to_xml.should == <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name">
    <uid name="joe" publisher.name="twitter" />
    <uid name="jack" publisher.name="digg" />
  </collection>
HEREDOC

  end

  it "should create collection with correct xml format with POST URL" do
    collection = Gnip::Collection.new('url-safe-name')
    collection.post_url = "http://example.com"
    collection.add_uid("joe", "twitter")
    collection.add_uid("jack", "digg")

    collection.to_xml.should == <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name" postUrl="http://example.com">
    <uid name="joe" publisher.name="twitter" />
    <uid name="jack" publisher.name="digg" />
  </collection>
HEREDOC
  end

   it 'should unmarshal from xml correctly' do
    collection_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name">
    <uid name="joe" publisher.name="twitter" />
    <uid name="jack" publisher.name="digg" />
  </collection>
HEREDOC
    collection = Gnip::Collection.from_xml(collection_xml)
    collection.name.should == "url-safe-name"
    collection.uids.size.should == 2
    collection.uids[0].name.should == 'joe'
    collection.uids[0].publisher_name.should == 'twitter'
    collection.post_url.should be_nil
   end

  it 'should unmarshal from xml correctly without uids' do
    collection_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name">
  </collection>
HEREDOC
    collection = Gnip::Collection.from_xml(collection_xml)
    collection.name.should == "url-safe-name"
    collection.uids.size.should == 0
    collection.post_url.should be_nil
  end

  it 'should unmarshal from xml correctly with POST URL' do
    collection_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name" postUrl="http://example.com">
    <uid name="joe" publisher.name="twitter" />
    <uid name="jack" publisher.name="digg" />
  </collection>
HEREDOC
    collection = Gnip::Collection.from_xml(collection_xml)
    collection.name.should == "url-safe-name"
    collection.uids.size.should == 2
    collection.uids[0].name.should == 'joe'
    collection.uids[0].publisher_name.should == 'twitter'
    collection.post_url.should == "http://example.com"
  end

  it "should allow adding and removing uids" do
    collection = Gnip::Collection.new('url-safe-name')
    collection.add_uid('joe','twitter')
    collection.add_uid("jack", "digg")
    collection.uids.size.should == 2
    collection.remove_uid("jack", "digg")
    collection.uids.size.should == 1
  end
end
